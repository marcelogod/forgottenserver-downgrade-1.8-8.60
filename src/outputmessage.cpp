// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "outputmessage.h"

#include "lockfree.h"
#include "protocol.h"
#include "scheduler.h"

extern Scheduler g_scheduler;

namespace {

using namespace std::chrono_literals;

// Inline constexpr constants avoid ODR issues and are friendly to headers/optimizations
inline constexpr uint16_t OUTPUTMESSAGE_FREE_LIST_CAPACITY = 2048;
inline constexpr auto AUTOSEND_DELAY_MIN = 5ms;   // High load (many players with data)
inline constexpr auto AUTOSEND_DELAY_MAX = 25ms;   // Low load (few players with data)
inline constexpr auto AUTOSEND_DELAY_DEFAULT = 10ms;
inline constexpr size_t AUTOSEND_HIGH_LOAD_THRESHOLD = 200; // protocols with pending data

	/**
	 * Sends all buffered messages to the protocols
	 *
	 * @param bufferedProtocols Pointer to the protocol vector (non-null)
	 * @note Must be called only from the dispatcher thread
	 * @note Marked as noexcept - failures will cause std::terminate
	 */
void sendAll(std::vector<Protocol_ptr>* bufferedProtocols) noexcept;

	/**
	 * Schedules the next automatic sending of messages
	 *
	 * @param bufferedProtocols Pointer to the protocol vector
	 * @param delay Adaptive delay for the next tick
	 * @note Must be called only from the dispatcher thread
	 */
void scheduleSendAll(std::vector<Protocol_ptr>* bufferedProtocols, std::chrono::milliseconds delay) noexcept
{
		g_scheduler.addEvent(createSchedulerTask(
			static_cast<int>(delay.count()),
			[bufferedProtocols]() { sendAll(bufferedProtocols); }
		));
	}

void sendAll(std::vector<Protocol_ptr>* bufferedProtocols) noexcept
{
		// dispatcher thread
		if (!bufferedProtocols || bufferedProtocols->empty()) [[unlikely]] {
			return;
		}

		// Sends the current buffer of each protocol, if present
		size_t activeCount = 0;
		for (auto& protocol : *bufferedProtocols) {
			auto& msg = protocol->getCurrentBuffer();
			if (msg) [[likely]] {
				protocol->send(std::move(msg));
				++activeCount;
			}
		}

		// Reschedule with adaptive delay based on how many protocols had data
		if (!bufferedProtocols->empty()) [[likely]] {
			auto delay = AUTOSEND_DELAY_DEFAULT;
			if (activeCount >= AUTOSEND_HIGH_LOAD_THRESHOLD) {
				delay = AUTOSEND_DELAY_MIN;
			} else if (activeCount == 0) {
				delay = AUTOSEND_DELAY_MAX;
			}
			scheduleSendAll(bufferedProtocols, delay);
		}
	}
} // namespace

void OutputMessagePool::addProtocolToAutosend(Protocol_ptr protocol)
{
	// THREAD-SAFETY: Must be called from dispatcher thread only
	// dispatcher thread
	if (bufferedProtocols.empty()) [[unlikely]] {
		scheduleSendAll(&bufferedProtocols, AUTOSEND_DELAY_DEFAULT);
	}
	bufferedProtocols.emplace_back(std::move(protocol));
}

void OutputMessagePool::removeProtocolFromAutosend(const Protocol_ptr& protocol)
{
	// THREAD-SAFETY: Must be called from dispatcher thread only
	// dispatcher thread
	auto it = std::find(bufferedProtocols.begin(), bufferedProtocols.end(), protocol);
	if (it != bufferedProtocols.end()) [[likely]] {
		// Swap-and-pop for O(1) removal - does not preserve order
		std::swap(*it, bufferedProtocols.back());
		bufferedProtocols.pop_back();
	}
}

OutputMessage_ptr OutputMessagePool::getOutputMessage()
{
	/**
	 * Uses the fixed lock-free allocator to create messages
	 *
	 * The fixed allocator guarantees:
	 * - Single allocations (n=1) use the lock-free pool
	 * - Block allocations (n>1) use the standard operator new
	 * - Works correctly with std::allocate_shared
	 *
	 * Pool capacity: 2048 messages
	 */
	return std::allocate_shared<OutputMessage>(LockfreePoolingAllocator<void, OUTPUTMESSAGE_FREE_LIST_CAPACITY>());
}

void OutputMessagePool::prewarmPool(size_t count)
{
	// Pre-allocate OutputMessage blocks and return them to the lock-free pool.
	// This avoids operator new() overhead during early gameplay.
	count = std::min(count, static_cast<size_t>(OUTPUTMESSAGE_FREE_LIST_CAPACITY));

	std::vector<OutputMessage_ptr> warmup;
	warmup.reserve(count);
	for (size_t i = 0; i < count; ++i) {
		warmup.emplace_back(getOutputMessage());
	}
	// All shared_ptrs go out of scope here, returning blocks to the pool
}

void OutputMessagePool::drainPool()
{
	// Free all pooled memory blocks so valgrind reports zero leaks.
	LockfreePoolRegistry::drainAll();
}
