#===============================================================================
#
#===============================================================================
class SubwayChallengeRules
  attr_reader :ruleset
  attr_reader :battletype
  attr_reader :levelAdjustment

  def initialize(ruleset = nil)
    @ruleset         = (ruleset) ? ruleset : SubwayRuleSet.new
    @battletype      = BattleTower.new
    @levelAdjustment = nil
    @battlerules     = []
  end

  def copy
    ret = SubwayChallengeRules.new(@ruleset.copy)
    ret.setBattleType(@battletype)
    ret.setLevelAdjustment(@levelAdjustment)
    for rule in @battlerules
      ret.addBattleRule(rule)
    end
    return ret
  end

  def setRuleset(rule)
    @ruleset = rule
    return self
  end

  def setBattleType(rule)
    @battletype = rule
    return self
  end

  def setLevelAdjustment(rule)
    @levelAdjustment = rule
    return self
  end

  def number
    return self.ruleset.number
  end

  def setNumber(number)
    self.ruleset.setNumber(number)
    return self
  end

  def setDoubleBattle(value)
    if value
      self.ruleset.setNumber(4)
      self.addBattleRule(DoubleBattle.new)
    else
      self.ruleset.setNumber(3)
      self.addBattleRule(SingleBattle.new)
    end
    return self
  end

  def adjustLevels(party1, party2)
    return @levelAdjustment.adjustLevels(party1, party2) if @levelAdjustment
    return nil
  end

  def unadjustLevels(party1, party2, adjusts)
    @levelAdjustment.unadjustLevels(party1, party2, adjusts) if @levelAdjustment && adjusts
  end

  def adjustLevelsBilateral(party1,party2)
    if @levelAdjustment && @levelAdjustment.type == LevelAdjustment::BothTeams
      return @levelAdjustment.adjustLevels(party1, party2)
    end
    return nil
  end

  def unadjustLevelsBilateral(party1,party2,adjusts)
    if @levelAdjustment && adjusts && @levelAdjustment.type == LevelAdjustment::BothTeams
      @levelAdjustment.unadjustLevels(party1, party2, adjusts)
    end
  end

  def addPokemonRule(rule)
    self.ruleset.addPokemonRule(rule)
    return self
  end

  def addLevelRule(minLevel,maxLevel,totalLevel)
    self.addPokemonRule(MinimumLevelRestriction.new(minLevel))
    self.addPokemonRule(MaximumLevelRestriction.new(maxLevel))
    self.addSubsetRule(TotalLevelRestriction.new(totalLevel))
    self.setLevelAdjustment(TotalLevelAdjustment.new(minLevel, maxLevel, totalLevel))
    return self
  end

  def addSubsetRule(rule)
    self.ruleset.addSubsetRule(rule)
    return self
  end

  def addTeamRule(rule)
    self.ruleset.addTeamRule(rule)
    return self
  end

  def addBattleRule(rule)
    @battlerules.push(rule)
    return self
  end

  def createBattle(scene, trainer1, trainer2)
    battle = @battletype.pbCreateBattle(scene, trainer1, trainer2)
    for p in @battlerules
      p.setRule(battle)
    end
    return battle
  end
end

#===============================================================================
# Subway Rules
#===============================================================================
def pbSubwaySinglesRules()
  ret = SubwayChallengeRules.new
  ret.setLevelAdjustment(CappedLevelAdjustment.new(50))
  ret.addPokemonRule(StandardRestrictionSubway.new)
  # ret.addTeamRule(SpeciesClause.new)
  # ret.addTeamRule(ItemClause.new)
  # ret.addBattleRule(SoulDewBattleClause.new)
  ret.setDoubleBattle(false)
  return ret
end

def pbSubwayDoublesRules()
  ret = SubwayChallengeRules.new
  ret.setLevelAdjustment(CappedLevelAdjustment.new(50))
  ret.addPokemonRule(StandardRestrictionSubway.new)
  ret.addTeamRule(SpeciesClause.new)
  ret.addTeamRule(ItemClause.new)
  ret.addBattleRule(SoulDewBattleClause.new)
  ret.setDoubleBattle(true)
  return ret
end

def pbSubwayRentalsRules()
  ret = SubwayChallengeRules.new
  ret.setLevelAdjustment(CappedLevelAdjustment.new(50))
  ret.addPokemonRule(StandardRestrictionSubway.new)
  ret.addTeamRule(SpeciesClause.new)
  ret.addTeamRule(ItemClause.new)
  ret.addBattleRule(SoulDewBattleClause.new)
  ret.setDoubleBattle(true)
  return ret
end

