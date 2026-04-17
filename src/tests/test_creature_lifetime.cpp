#define BOOST_TEST_MODULE creature_lifetime

#include "../otpch.h"

#include "../creature.h"

#include <boost/test/unit_test.hpp>

namespace {

class TestCreature final : public Creature
{
public:
	const std::string& getName() const override { return name; }
	const std::string& getNameDescription() const override { return name; }
	std::string getDescription(int32_t) const override { return name; }
	CreatureType_t getType() const override { return CREATURETYPE_MONSTER; }
	void setID() override {}
	void removeList() override {}
	void addList() override {}

private:
	std::string name = "test creature";
};

std::shared_ptr<TestCreature> makeTestCreature()
{
	return std::make_shared<TestCreature>();
}

} // namespace

BOOST_AUTO_TEST_CASE(creature_lifetime_registry_tracks_destroyed_creature)
{
	const Creature* rawCreature = nullptr;
	{
		auto creature = makeTestCreature();
		rawCreature = creature.get();
		BOOST_TEST(Creature::isAlive(rawCreature));
	}

	BOOST_TEST(!Creature::isAlive(rawCreature));
}

BOOST_AUTO_TEST_CASE(summon_lifecycle_uses_weak_owner_links)
{
	auto master = makeTestCreature();
	auto summon = makeTestCreature();

	BOOST_TEST(summon->setMaster(master.get()));
	BOOST_TEST(summon->getMaster() == master.get());
	BOOST_TEST(master->getSummonCount() == 1U);

	summon.reset();

	BOOST_TEST(master->getSummonCount() == 0U);
	BOOST_TEST(master->getSummons().empty());
}

BOOST_AUTO_TEST_CASE(remove_master_detaches_summon_from_owner_list)
{
	auto master = makeTestCreature();
	auto summon = makeTestCreature();

	BOOST_TEST(summon->setMaster(master.get()));
	BOOST_TEST(master->getSummonCount() == 1U);

	summon->removeMaster();

	BOOST_TEST(summon->getMaster() == nullptr);
	BOOST_TEST(master->getSummonCount() == 0U);
	BOOST_TEST(master->getSummons().empty());
}

BOOST_AUTO_TEST_CASE(changing_master_detaches_from_previous_owner)
{
	auto oldMaster = makeTestCreature();
	auto newMaster = makeTestCreature();
	auto summon = makeTestCreature();

	BOOST_TEST(summon->setMaster(oldMaster.get()));
	BOOST_TEST(summon->setMaster(newMaster.get()));

	BOOST_TEST(summon->getMaster() == newMaster.get());
	BOOST_TEST(oldMaster->getSummonCount() == 0U);
	BOOST_TEST(newMaster->getSummonCount() == 1U);
}
