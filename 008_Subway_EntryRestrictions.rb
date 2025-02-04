## Regulation A
class StandardRestrictionSubway
  def isValid?(pkmn)
    return false if !pkmn || pkmn.egg?
    pkmn.species_data.abilities.each do |a|
      return true if [:TRUANT].include?(a)
    end
    return false if [:WYNAUT, :WOBBUFFET, :DEOXYS, :KANGASKHAN, :URSHIFU, :GHOLDENGO, :SHEDINJA, :KARTANA].include?(pkmn.species)
    bst = 0
    pkmn.baseStats.each_value { |s| bst += s }
    return false if bst > 600
    return true
  end
end

