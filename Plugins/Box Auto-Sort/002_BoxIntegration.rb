module BoxAutoSort
  METHODS = [
    :LEVEL_ASC, :LEVEL_DESC, :ALPHABET, :ALPHABET_REV,
    :TYPE_PRIMARY, :TYPE_DUAL, :CATCH_DATE, :SHINY_FIRST,
    :SPECIES_ID, :FORM_ID, :FRIENDSHIP, :NATURE
  ]

  def self.show_sort_menu(storage, box_index = nil)
    return false unless ENABLED
    box_index = storage.currentBox if box_index.nil?
    commands = METHODS.map { |method| get_sort_name(method) }
    commands << _INTL("Cancel")
    choice = pbMessage(_INTL("How would you like to sort this box?"), commands, commands.length - 1)
    return false if choice < 0 || choice >= METHODS.length
    perform_sort(storage, box_index, METHODS[choice])
  end

  def self.perform_sort(storage, box_index, method)
    sorter = BoxSorter.new(storage, box_index)
    preview = sorter.preview_sort(method)
    if preview.empty?
      pbMessage(_INTL("This box is empty!"))
      return false
    end
    if SHOW_PREVIEW
      count = [preview.length, PREVIEW_COUNT].min
      message = _INTL("Preview of first {1} Pokémon:", count) + "\n"
      preview.first(count).each_with_index do |entry, index|
        pokemon = entry[0]
        message += _INTL("{1}. {2} (Lv.{3})", index + 1, pokemon.name, pokemon.level) + "\n"
      end
      message += "\n" + _INTL("Apply this sorting?")
      return false unless pbConfirmMessage(message)
    end
    return false unless sorter.sort_pokemon(method)
    pbPlayDecisionSE
    pbMessage(_INTL("Box has been sorted!"))
    true
  end
end

module BoxAutoSortMenu
  def pbBoxCommands
    return super unless BoxAutoSort::ENABLED
    commands = [_INTL("Jump"), _INTL("Wallpaper"), _INTL("Name"), _INTL("Sort"), _INTL("Cancel")]
    can_swap = defined?(CAN_SWAP_BOXES) && CAN_SWAP_BOXES && @scene.respond_to?(:pbSwapBoxes)
    commands.insert(1, _INTL("Swap")) if can_swap
    choice = pbShowCommands(_INTL("What do you want to do?"), commands)
    if can_swap && choice == 1
      box = @scene.pbChooseBox(_INTL("Swap with which Box?"))
      @scene.pbSwapBoxes(box) if box >= 0
      return
    end
    choice -= 1 if can_swap && choice > 1
    case choice
    when 0
      box = @scene.pbChooseBox(_INTL("Jump to which Box?"))
      @scene.pbJumpToBox(box) if box >= 0
    when 1
      papers = @storage.availableWallpapers
      index = papers[1].index(@storage[@storage.currentBox].background) || 0
      wallpaper = pbShowCommands(_INTL("Pick the wallpaper."), papers[0], index)
      @scene.pbChangeBackground(papers[1][wallpaper]) if wallpaper >= 0
    when 2
      @scene.pbBoxName(_INTL("Box name?"), 0, 12)
    when 3
      if BoxAutoSort.show_sort_menu(@storage, @storage.currentBox)
        @scene.pbHardRefresh
      end
    end
  end
end

PokemonStorageScreen.prepend(BoxAutoSortMenu) if defined?(PokemonStorageScreen)

MenuHandlers.add(:pc_menu, :box_auto_sort, {
  "name"      => _INTL("Box Auto-Sort"),
  "order"     => 15,
  "condition" => proc { BoxAutoSort::ENABLED },
  "effect"    => proc { |_menu|
    commands = (0...$PokemonStorage.maxBoxes).map do |index|
      box = $PokemonStorage[index]
      _INTL("{1} ({2}/{3})", box.name, box.nitems, box.length)
    end
    commands << _INTL("Cancel")
    choice = pbMessage(_INTL("Which box to sort?"), commands, commands.length - 1)
    BoxAutoSort.show_sort_menu($PokemonStorage, choice) if choice >= 0 && choice < $PokemonStorage.maxBoxes
    next false
  }
})

if defined?(UI::PokemonStorage)
UI::PokemonStorage::ACTIONS.add(:box_auto_sort, {
  :effect => proc { |screen|
    BoxAutoSort.show_sort_menu(screen.storage, screen.box)
    screen.refresh_box
  }
})

MenuHandlers.add(:storage_box_interact, :box_auto_sort, {
  "name"  => _INTL("Sort"),
  "order" => 25
})

end
