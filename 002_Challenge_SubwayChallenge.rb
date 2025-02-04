#===============================================================================
#
#===============================================================================
class SubwayChallenge
  attr_reader :currentChallenge

  SinglesID   = 0
  DoublesID  = 1
  RentalsID   = 2

  def initialize
    @bc = SubwayChallengeData.new
    @currentChallenge = -1
    @types = {}
  end

  def set(id, numrounds, rules)
    @id = id
    @numRounds = numrounds
    @rules = rules
    case id
    when id[/^singles/]
      doubles = false
      numPokemon = 3
      battletype = SinglesID
      mode = 1
    when id[/^doubles/]
      doubles = true
      numPokemon = 4
      battletype = DoublesID
      mode = 2
    when id[/^rentals/]
      doubles = true
      numPokemon = 4
      battletype = RentalsID
      mode = 3
    end
    register(id, doubles, numPokemon, battletype, mode)
    pbWriteCup(id, rules)
  end

  def register(id, doublebattle, numPokemon, battletype, mode)
    ensureType(id)
    if battletype == RentalsID
      @bc.setExtraData(SubwayRentalsData.new(@bc))
      numPokemon = 4
      battletype = RentalsID
    end
    @rules = modeToRules(doublebattle, numPokemon, battletype, mode) if !@rules
  end

  def rules
    if !@rules
      @rules = modeToRules(self.data.doublebattle, self.data.numPokemon,
                           self.data.battletype, self.data.mode)
    end
    return @rules
  end

  def modeToRules(doublebattle, numPokemon, battletype, mode)
    rules = SubwayRuleSet.new
    # Set the battle type
    case battletype
    when SinglesID   # Single Battles
      rules.setBattleType(SubwaySingles.new)
    when DoublesID   # Double Battles
      rules.setBattleType(SubwayDoubles.new)
      doublebattle = true
    when RentalsID   # Rental Battles
      rules.setBattleType(SubwayRentals.new)
      doublebattle = true
    else   # Factory works the same as Tower
      rules.setBattleType(BattleTower.new)
    end
    # Set standard rules and maximum level
    case mode
    when 1, 2, 3
      rules.setRuleset(StandardRulesSubway.new(numPokemon, GameData::GrowthRate.max_level))
    else
      rules.setRuleset(StandardRules.new(numPokemon, GameData::GrowthRate.max_level))
      rules.setLevelAdjustment(OpenLevelAdjustment.new(50))
    end
    # Set whether battles are single or double
    if doublebattle
      rules.addBattleRule(DoubleBattle.new)
    else
      rules.addBattleRule(SingleBattle.new)
    end
    return rules
  end

  def start(*args) # JERICOR
    t = ensureType(@id)
    @currentChallenge = @id   # must appear before pbStart
    @bc.pbStart(t, @numRounds, 0)
  end

  def start2(*args) # ARGENTA
    t = ensureType(@id)
    @currentChallenge = @id   # must appear before pbStart
    @bc.pbStart(t, @numRounds, 1)
  end

  def start3(*args) # ESPINAL
    t = ensureType(@id)
    @currentChallenge = @id   # must appear before pbStart
    @bc.pbStart(t, @numRounds, 2)
  end

  def start4(*args) # DELILA
    t = ensureType(@id)
    @currentChallenge = @id   # must appear before pbStart
    @bc.pbStart(t, @numRounds, 3)
  end

  def start5(*args) # KOKURAN
    t = ensureType(@id)
    @currentChallenge = @id   # must appear before pbStart
    @bc.pbStart(t, @numRounds, 4)
  end

  def pbStart(challenge)
  end

  def pbEnd
    if @currentChallenge != -1
      ensureType(@currentChallenge).saveWins(@bc)
      @currentChallenge = -1
    end
    @bc.pbEnd
  end

  def pbSubwayBattle
    return @bc.extraData.pbBattle(self) if @bc.extraData   # Battle Factory
    opponent = pbGenerateSubwayTrainer(self.nextTrainer, self.rules)
    bttrainers = pbGetSubwayTrainers(@id)
    trainerdata = bttrainers[self.nextTrainer]
    ret = pbSubwayOrganizedBattleEx(opponent,self.rules,
       pbGetMessageFromHash(MessageTypes::EndSpeechLose, trainerdata[4]),
       pbGetMessageFromHash(MessageTypes::EndSpeechWin, trainerdata[3]))
    return ret
  end

  def pbSInChallenge?
    return pbInProgress?
  end

  def pbInProgress?
    return @bc.inProgress
  end

  def pbResting?
    return @bc.resting
  end

  def extra;        @bc.extraData;    end
  def decision;     @bc.decision;     end
  def wins;         @bc.wins;         end
  def swaps;        @bc.swaps;        end
  def battleNumber; @bc.battleNumber; end
  def nextTrainer;  @bc.nextTrainer;  end
  def pbGoOn;       @bc.pbGoOn;       end
  def pbAddWin;     @bc.pbAddWin;     end
  def pbCancel;     @bc.pbCancel;     end
  def pbRest;       @bc.pbRest;       end
  def pbMatchOver?; @bc.pbMatchOver?; end
  def pbGoToStart;  @bc.pbGoToStart;  end

  def setDecision(value)
    @bc.decision = value
  end

  def setParty(value)
    @bc.setParty(value)
  end

  def data
    return nil if !pbInProgress? || @currentChallenge < 0
    return ensureType(@currentChallenge).clone
  end

  def getCurrentWins(challenge)
    return ensureType(challenge).currentWins
  end

  def getPreviousWins(challenge)
    return ensureType(challenge).previousWins
  end

  def getMaxWins(challenge)
    return ensureType(challenge).maxWins
  end

  def getCurrentSwaps(challenge)
    return ensureType(challenge).currentSwaps
  end

  def getPreviousSwaps(challenge)
    return ensureType(challenge).previousSwaps
  end

  def getMaxSwaps(challenge)
    return ensureType(challenge).maxSwaps
  end

  private

  def ensureType(id)
    @types[id] = SubwayChallengeType.new if !@types[id]
    return @types[id]
  end
end

#===============================================================================
#
#===============================================================================
class SubwayChallengeData
  attr_reader   :battleNumber
  attr_reader   :numRounds
  attr_reader   :party
  attr_reader   :inProgress
  attr_reader   :resting
  attr_reader   :wins
  attr_reader   :swaps
  attr_accessor :decision
  attr_reader   :extraData

  def initialize
    reset
  end

  def setExtraData(value)
    @extraData = value
  end

  def setParty(value)
    if @inProgress
      $Trainer.party = value
      @party = value
    else
      @party = value
    end
  end

  def pbStart(t, numRounds, type)
    @inProgress   = true
    @resting      = false
    @decision     = 0
    @swaps        = t.currentSwaps
    @wins         = 0
    @battleNumber = 1
    @trainers     = []
    raise _INTL("Number of rounds is 0 or less.") if numRounds <= 0
    @numRounds = numRounds
    # Get all the trainers for the next set of battles
    btTrainers = pbGetSubwayTrainers(pbSubwayChallenge.currentChallenge)
    while @trainers.length < @numRounds
      # Preguntamos si la ronda es la 2
      newtrainer = pbSubwayChallengeTrainer(@wins + @trainers.length, btTrainers, type)
      found = false
      for tr in @trainers
        found = true if tr == newtrainer
      end
      @trainers.push(newtrainer) if !found
    end
    @start = [$game_map.map_id, $game_player.x, $game_player.y]
    @oldParty = $Trainer.party
    $Trainer.party = @party if @party
    Game.save(safe: true)
  end

  def pbGoToStart
    if $scene.is_a?(Scene_Map)
      $game_temp.player_transferring  = true
      $game_temp.player_new_map_id    = @start[0]
      $game_temp.player_new_x         = @start[1]
      $game_temp.player_new_y         = @start[2]
      $game_temp.player_new_direction = 8
      $scene.transfer_player
    end
  end

  def pbAddWin
    return if !@inProgress
    @battleNumber += 1
    @wins += 1
  end

  def pbAddSwap
    @swaps += 1 if @inProgress
  end

  def pbMatchOver?
    return true if !@inProgress || @decision != 0
    return @battleNumber > @numRounds
  end

  def pbRest
    return if !@inProgress
    @resting = true
    pbSaveInProgress
  end

  def pbGoOn
    return if !@inProgress
    @resting = false
    pbSaveInProgress
  end

  def pbCancel
    $Trainer.party = @oldParty if @oldParty
    reset
  end

  def pbEnd
    $Trainer.party = @oldParty
    return if !@inProgress
    save = (@decision != 0)
    reset
    $game_map.need_refresh = true
    Game.save(safe: true) if save
  end

  def nextTrainer
    return @trainers[@battleNumber - 1]
  end

  private

  def reset
    @inProgress   = false
    @resting      = false
    @start        = nil
    @decision     = 0
    @wins         = 0
    @swaps        = 0
    @battleNumber = 0
    @trainers     = []
    @oldParty     = nil
    @party        = nil
    @extraData    = nil
  end

  def pbSaveInProgress
    oldmapid     = $game_map.map_id
    oldx         = $game_player.x
    oldy         = $game_player.y
    olddirection = $game_player.direction
    $game_map.map_id = @start[0]
    $game_player.moveto2(@start[1], @start[2])
    $game_player.direction = 8   # facing up
    Game.save(safe: true)
    $game_map.map_id = oldmapid
    $game_player.moveto2(oldx, oldy)
    $game_player.direction = olddirection
  end
end

#===============================================================================
#
#===============================================================================
class SubwayChallengeType
  attr_accessor :currentWins
  attr_accessor :previousWins
  attr_accessor :maxWins
  attr_accessor :currentSwaps
  attr_accessor :previousSwaps
  attr_accessor :maxSwaps
  attr_reader   :doublebattle
  attr_reader   :numPokemon
  attr_reader   :battletype
  attr_reader   :mode

  def initialize
    @previousWins  = 0
    @maxWins       = 0
    @currentWins   = 0
    @currentSwaps  = 0
    @previousSwaps = 0
    @maxSwaps      = 0
  end

  def saveWins(challenge)
    if challenge.decision == 0     # if undecided
      @currentWins  = 0
      @currentSwaps = 0
    else
      if challenge.decision == 1   # if won
        @currentWins  = challenge.wins
        @currentSwaps = challenge.swaps
      else                       # if lost
        @currentWins  = 0
        @currentSwaps = 0
      end
      @maxWins       = [@maxWins, challenge.wins].max
      @previousWins  = challenge.wins
      @maxSwaps      = [@maxSwaps, challenge.swaps].max
      @previousSwaps = challenge.swaps
    end
  end
end

#===============================================================================
# Battle Factory data
#===============================================================================
class SubwayRentalsData
  def initialize(bcdata)
    @bcdata = bcdata
  end

  def pbPrepareRentals
    @rentals = pbBattleFactoryPokemon(pbSubwayChallenge.rules, @bcdata.wins, @bcdata.swaps, [])
    @trainerid = @bcdata.nextTrainer
    bttrainers = pbGetSubwayTrainers(pbSubwayChallenge.currentChallenge)
    trainerdata = bttrainers[@trainerid]
    @opponent = NPCTrainer.new(
       pbGetMessageFromHash(MessageTypes::TrainerNames, trainerdata[1]),
       trainerdata[0])
    opponentPkmn = pbBattleFactoryPokemon(pbSubwayChallenge.rules, @bcdata.wins, @bcdata.swaps, @rentals)
    @opponent.party = opponentPkmn.shuffle[0, 3]
  end

  def pbChooseRentals
    pbFadeOutIn {
      scene = BattleSwapScene.new
      screen = BattleSwapScreen.new(scene)
      @rentals = screen.pbStartRent(@rentals)
      @bcdata.pbAddSwap
      @bcdata.setParty(@rentals)
    }
  end

  def pbPrepareSwaps
    @oldopponent = @opponent.party
    trainerid = @bcdata.nextTrainer
    bttrainers = pbGetSubwayTrainers(pbSubwayChallenge.currentChallenge)
    trainerdata = bttrainers[trainerid]
    @opponent = NPCTrainer.new(
       pbGetMessageFromHash(MessageTypes::TrainerNames, trainerdata[1]),
       trainerdata[0])
    opponentPkmn = pbBattleFactoryPokemon(pbSubwayChallenge.rules, @bcdata.wins, @bcdata.swaps,
       [].concat(@rentals).concat(@oldopponent))
    @opponent.party = opponentPkmn.shuffle[0, 3]
  end

  def pbChooseSwaps
    swapMade = true
    pbFadeOutIn {
      scene = BattleSwapScene.new
      screen = BattleSwapScreen.new(scene)
      swapMade = screen.pbStartSwap(@rentals, @oldopponent)
      @bcdata.pbAddSwap if swapMade
      @bcdata.setParty(@rentals)
    }
    return swapMade
  end

  def pbBattle(challenge)
    bttrainers = pbGetSubwayTrainers(pbSubwayChallenge.currentChallenge)
    trainerdata = bttrainers[@trainerid]
    return pbSubwayOrganizedBattleEx(@opponent, challenge.rules,
       pbGetMessageFromHash(MessageTypes::EndSpeechLose, trainerdata[4]),
       pbGetMessageFromHash(MessageTypes::EndSpeechWin, trainerdata[3]))
  end
end
