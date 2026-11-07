module BoxAutoSort
  class BoxSorter
    def initialize(storage, box_index)
      @storage = storage
      @box_index = box_index
      @box = @storage[@box_index]
    end

    def get_pokemon_list
      pokemon_list = []
      (0...PokemonBox::BOX_SIZE).each do |i|
        pokemon = @storage[@box_index, i]
        pokemon_list << [pokemon, i] if pokemon
      end
      return pokemon_list
    end

    def sort_pokemon(sort_method)
      pokemon_list = get_pokemon_list
      return false if pokemon_list.empty?

      sorted_list = case sort_method
      when :LEVEL_ASC
        pokemon_list.sort { |a, b| a[0].level <=> b[0].level }
      when :LEVEL_DESC
        pokemon_list.sort { |a, b| b[0].level <=> a[0].level }
      when :ALPHABET
        pokemon_list.sort { |a, b| a[0].name <=> b[0].name }
      when :ALPHABET_REV
        pokemon_list.sort { |a, b| b[0].name <=> a[0].name }
      when :TYPE_PRIMARY
        pokemon_list.sort { |a, b| compare_types(a[0], b[0]) }
      when :TYPE_DUAL
        pokemon_list.sort { |a, b| compare_types_dual(a[0], b[0]) }
      when :CATCH_DATE
        pokemon_list.sort { |a, b| compare_catch_date(a[0], b[0]) }
      when :SHINY_FIRST
        pokemon_list.sort { |a, b| compare_shiny_first(a[0], b[0]) }
      when :SPECIES_ID
        pokemon_list.sort { |a, b| compare_species_id(a[0], b[0]) }
      when :FORM_ID
        pokemon_list.sort { |a, b| compare_form_id(a[0], b[0]) }
      when :FRIENDSHIP
        pokemon_list.sort { |a, b| b[0].happiness <=> a[0].happiness }
      when :NATURE
        pokemon_list.sort { |a, b| a[0].nature.name <=> b[0].nature.name }
      else
        return false
      end

      apply_sorted_order(sorted_list)
      return true
    end

    def preview_sort(sort_method)
      pokemon_list = get_pokemon_list
      return [] if pokemon_list.empty?

      case sort_method
      when :LEVEL_ASC
        return pokemon_list.sort { |a, b| a[0].level <=> b[0].level }
      when :LEVEL_DESC
        return pokemon_list.sort { |a, b| b[0].level <=> a[0].level }
      when :ALPHABET
        return pokemon_list.sort { |a, b| a[0].name <=> b[0].name }
      when :ALPHABET_REV
        return pokemon_list.sort { |a, b| b[0].name <=> a[0].name }
      when :TYPE_PRIMARY
        return pokemon_list.sort { |a, b| compare_types(a[0], b[0]) }
      when :TYPE_DUAL
        return pokemon_list.sort { |a, b| compare_types_dual(a[0], b[0]) }
      when :CATCH_DATE
        return pokemon_list.sort { |a, b| compare_catch_date(a[0], b[0]) }
      when :SHINY_FIRST
        return pokemon_list.sort { |a, b| compare_shiny_first(a[0], b[0]) }
      when :SPECIES_ID
        return pokemon_list.sort { |a, b| compare_species_id(a[0], b[0]) }
      when :FORM_ID
        return pokemon_list.sort { |a, b| compare_form_id(a[0], b[0]) }
      when :FRIENDSHIP
        return pokemon_list.sort { |a, b| b[0].happiness <=> a[0].happiness }
      when :NATURE
        return pokemon_list.sort { |a, b| a[0].nature.name <=> b[0].nature.name }
      else
        return pokemon_list
      end
    end

    private

    def apply_sorted_order(sorted_list)
      (0...PokemonBox::BOX_SIZE).each do |i|
        @storage[@box_index, i] = nil
      end

      sorted_list.each_with_index do |pokemon_data, new_index|
        @storage[@box_index, new_index] = pokemon_data[0]
      end
    end

    def compare_types(pokemon_a, pokemon_b)
      type_a = GameData::Type.get(pokemon_a.types[0]).name
      type_b = GameData::Type.get(pokemon_b.types[0]).name
      comparison = type_a <=> type_b
      return comparison != 0 ? comparison : pokemon_a.name <=> pokemon_b.name
    end

    def compare_types_dual(pokemon_a, pokemon_b)
      types_a = pokemon_a.types.map { |type| GameData::Type.get(type).name }.join("/")
      types_b = pokemon_b.types.map { |type| GameData::Type.get(type).name }.join("/")
      comparison = types_a <=> types_b
      return comparison != 0 ? comparison : pokemon_a.name <=> pokemon_b.name
    end

    def compare_catch_date(pokemon_a, pokemon_b)
      date_a = pokemon_a.timeReceived || Time.new(2000, 1, 1)
      date_b = pokemon_b.timeReceived || Time.new(2000, 1, 1)
      comparison = date_b <=> date_a
      return comparison != 0 ? comparison : pokemon_a.name <=> pokemon_b.name
    end

    def compare_shiny_first(pokemon_a, pokemon_b)
      shiny_a = pokemon_a.shiny? ? 0 : 1
      shiny_b = pokemon_b.shiny? ? 0 : 1
      comparison = shiny_a <=> shiny_b
      return comparison != 0 ? comparison : pokemon_a.name <=> pokemon_b.name
    end

    def species_number(pokemon)
      data = GameData::Species.get(pokemon.species)
      return data.id_number if data.respond_to?(:id_number)
      @species_order ||= begin
        order = {}
        GameData::Species.each_species { |species| order[species.id] = order.length }
        order
      end
      @species_order[data.species] || @species_order[data.id] || @species_order.length
    end

    def compare_species_id(pokemon_a, pokemon_b)
      comparison = species_number(pokemon_a) <=> species_number(pokemon_b)
      return comparison != 0 ? comparison : pokemon_a.name <=> pokemon_b.name
    end

    def compare_form_id(pokemon_a, pokemon_b)
      species_comparison = species_number(pokemon_a) <=> species_number(pokemon_b)
      return species_comparison if species_comparison != 0

      form_a = pokemon_a.form || 0
      form_b = pokemon_b.form || 0
      form_comparison = form_a <=> form_b
      return form_comparison != 0 ? form_comparison : pokemon_a.name <=> pokemon_b.name
    end
  end

  def self.get_sort_name(sort_method)
    case sort_method
    when :LEVEL_ASC then return _INTL("Level (Low to High)")
    when :LEVEL_DESC then return _INTL("Level (High to Low)")
    when :ALPHABET then return _INTL("Alphabetical (A-Z)")
    when :ALPHABET_REV then return _INTL("Alphabetical (Z-A)")
    when :TYPE_PRIMARY then return _INTL("Primary Type")
    when :TYPE_DUAL then return _INTL("Type Combination")
    when :CATCH_DATE then return _INTL("Catch Date")
    when :SHINY_FIRST then return _INTL("Shiny First")
    when :SPECIES_ID then return _INTL("National Dex")
    when :FORM_ID then return _INTL("Forms")
    when :FRIENDSHIP then return _INTL("Friendship")
    when :NATURE then return _INTL("Nature")
    else return _INTL("Unknown")
    end
  end

  def self.get_sort_description(sort_method)
    case sort_method
    when :LEVEL_ASC then return _INTL("Sort from Level 1 to 100")
    when :LEVEL_DESC then return _INTL("Sort from Level 100 to 1")
    when :ALPHABET then return _INTL("Sort alphabetically from A to Z")
    when :ALPHABET_REV then return _INTL("Sort alphabetically from Z to A")
    when :TYPE_PRIMARY then return _INTL("Sort by primary type")
    when :TYPE_DUAL then return _INTL("Sort by type combination")
    when :CATCH_DATE then return _INTL("Sort by catch date (newest first)")
    when :SHINY_FIRST then return _INTL("Shiny Pokémon come first")
    when :SPECIES_ID then return _INTL("Sort by National Dex number")
    when :FORM_ID then return _INTL("Sort by species and form")
    when :FRIENDSHIP then return _INTL("Sort by friendship level")
    when :NATURE then return _INTL("Sort by nature alphabetically")
    else return _INTL("Unknown sorting method")
    end
  end
end
