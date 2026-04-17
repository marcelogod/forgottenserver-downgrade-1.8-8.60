#define BOOST_TEST_MODULE storage_maps

#include "../otpch.h"

#include "../creature.h"
#include "../game.h"

#include <absl/container/flat_hash_map.h>
#include <boost/test/unit_test.hpp>
#include <type_traits>

BOOST_AUTO_TEST_CASE(storage_maps_use_flat_hash_map)
{
	static_assert(std::is_same_v<Creature::StorageMap, absl::flat_hash_map<uint32_t, int64_t>>);
	static_assert(std::is_same_v<Game::StorageMap, absl::flat_hash_map<uint32_t, int64_t>>);

	BOOST_TEST(true);
}
