# By: 
# CSE341 -- Homework 7

### Insert WARMUP code here. ###################################################
# takes an Enumerable as a parameter and prints everything
# in passed enum on different lines in sorted order.
def print_indented(enum)
  result = enum.sort {|a,b| a.to_s <=> b.to_s}
  result.each {|x| puts "\s\s#{x.to_s}"}
end

# takes an Enumerable and an object.  Detects if passed obj
# is in the enum and if it is sends obj as parameter to block
# called with when_detected, else returns nil
def when_detected(enum, o)
  result = enum.detect {|x| x.to_s == o.to_s}
  if result
    yield result
  end
end


### End of WARMUP code. ########################################################

class Module # An example of metaprogramming for the help system.
  private
  # A method that will set the help text for the given command.
  def set_cmd_help cmd_name, help_str
    help_var = ("help_"+cmd_name.to_s).to_sym
    define_method help_var do help_str end
  end
end

# A global state mixin.  Contains error recovery for bad player
# commands, a help system, and stubs for the basic methods any state
# needs in order to work properly in our game design.
module SystemState

  # For any unknown command entered by a player, this method will be
  # invoked to inform the player.  self is returned as the new active
  # state.
  def method_missing m, *args
    if m.to_s[0..3] === "cmd_" # Check if it's a game command.
      puts "Invalid command: please try again or use the 'help' command."

      # Since this method is called in place of a command method,
      # it must act like a command method and return a State.
      self
    else # Otherwise, it's a real missing method.
      super.method_missing m, *args
    end
  end

  set_cmd_help :help, "\t\t\t --  print available list of commands"

  # A global help command for a player to call at any time.  This will
  # print all available commands for the user and return self, not
  # changing the game state.
  def cmd_help
    cmd_names = self.public_methods.find_all {|m| m =~ /^cmd_/}
    cmd_help = cmd_names.map do |cmd|
      cmd_name = cmd.to_s[4..-1]
      help_method = "help_"+cmd_name
      cmd_help = ""
      cmd_help = self.send help_method if self.respond_to? help_method
      
      cmd_name + " " + cmd_help
    end

    puts "These are the currently available commands:"
    print_indented cmd_help
    self
  end

  set_cmd_help :quit, "\t\t\t --  quit the game"

  # Set the game as finished.
  def cmd_quit
    @endgame = true
    self
  end

  # Returns true if the quit command has been called.
  def finished?
    @endgame
  end

  # When a state is finished, this method will be called to inform the
  # user of the results.  This stub will raise an exception and must
  # be overridden in any state that has a finished? method that
  # returns true.
  def print_result
    # Thank the user for dropping by.
    puts
    puts "Thanks for dropping by!"
  end
end

# A simple state that signals a finished game and has a print_result
# informing the user of a failure game conclusion.
class FailureState
  # As all good state classes must, include the SystemState module.
  include SystemState

  # Always return true to signal an end game scenario.
  def finished?
    true
  end

  # Prints a failure message for the player.
  def print_result
    puts
    puts "You failed!!!"
  end
end

# A simple state that signals a finished game and has a print_result
# informing the user of a victorious game conclusion.
class VictoryState
  # As all good state classes must, include the SystemState module.
  include SystemState

  # Always returns true to signal an end game scenario.
  def finished?
    true
  end

  # Prints a congratulatory message for the player.
  def print_result
    puts
    puts "Good job!!! You win!!!"
  end
end

# The humble ancestor for all items or enemies.
class Entity
  attr_reader :tag

  def initialize tag
    @tag = tag
  end

  def to_s
    @tag
  end
end


####  Insert YOUR ADVENTURE GAME code here. ####################################




## TODO: Your SystemState extension should go here #############################


module SystemState
  #handles moving from one room to another
  def move_to_room(world, room)
    if room == world[:victory] #if move to a victory room
      return VictoryRoom.new(world,room)
    elsif room == world[:final_room] #if it is a final room
      return VictoryState.new
    elsif room == world[:training_room] #if its a training room
      return TrainingState.new(world, room)
    elsif room == world[:boss1] #if its a cody boss room
      return CodyState.new(world,room)
    elsif world[:rooms][room].include?(:enemies)#if there are enemies in room
      return FightState.new(world, room)
    elsif room == world[:shop_room] #if its the shop room
      return ShopState.new(world, room)
    elsif room == world[:enlightend_room2] #if its a tim enlightenment room
      return EnlightendStateTim.new(world,room)
    elsif room == world[:enlightend_room1] #if its a james enlightenment room
      return EnlightendStateJames.new(world,room)
    else
      return RoomState.new(world, room)    
    end
  end
end
      
    
    
## TODO: Your PlayerState mixin module should go here ##########################
module PlayerState
  
  set_cmd_help :health, "\t\t --  displays your current health"

  # allows user to check current health
  def cmd_health
    puts "#{@world[:health]}"
    self
  end

  set_cmd_help :gold, "\t\t\t --  displays your current gold"
  #allows user to check current gold
  def cmd_gold
    puts "#{@world[:gold]}"
    self
  end

  set_cmd_help :inventory, "\t\t --  displays your current inventory"
  
  # allows user to check current inventory
  def cmd_inventory
    # if an inventory exists and if its not empty
    if @world[:inventory] and not @world[:inventory].empty?
      print_indented(@world[:inventory])
    else
      puts "There is nothing in your inventory"
    end
    self
  end
  
  set_cmd_help :equip_weapon, "<weapon>\t --  equips a weapon from your inventory"
  
  # allows user to equip a weapon from inventory
  def cmd_equip_weapon(item=nil)
    # if an item is passed
    if item
      equip(item, :weapon)
    else
      puts "Equip what weapon?"
    end
    self
  end
  
  set_cmd_help :equip_armor, "<armor>\t --  equips an armor from your inventory"
  # allows user to equip an armor from inventory
  def cmd_equip_armor(item=nil)
    # if item is passed
    if item
      equip(item, :armor)
    else
      puts "Equip what armor?"
    end
    self
  end

  set_cmd_help :currently_equipped, "\t --  reports current equipped items"
  
  # allows user to check currently equipped items
  def cmd_currently_equipped
    # if there is anything equipped
    if @world[:equipped]
      # if there is a weapon equipped
      if @world[:equipped][:weapon]
        puts "Weapon: #{@world[:equipped][:weapon]}"
      else
        puts "Weapon: none"
      end
      # if there is an armor equipped
      if @world[:equipped][:armor]
        puts "Armor: #{@world[:equipped][:armor]}"
      else
        puts "Weapon: none"
      end
    else
      puts "No items currently equipped"
    end
    self
  end
  
  #helper which allows equipping item to certain spot
  def equip(item, slot)
    # if there is an inventory and if its not empty
    if @world[:inventory] and not @world[:inventory].empty?
      result = when_detected(@world[:inventory], item) do |x|
        # if there is anything equipped
        if @world[:equipped]
          # if there is anything equipped in slot
          if @world[:equipped][slot]
            @world[:inventory].push(@world[:equipped][slot])
          end
        else
          @world[:equipped] = Hash.new
        end
        puts "You have equipped #{x}"
        @world[:equipped][slot] = x
        @world[:inventory].delete(x)
      end
      # if item is not part of the inventory
      if result == nil
        puts "That item is not in your inventory"
      end
    else
      puts "There is nothing in your inventory to equip"
    end
  end
end





# The State of the game when a player is peacefully hanging out in a
# particular room in the world.
class RoomState
  # As all good state classes must, include the SystemState module.
  include SystemState
  include PlayerState # We also want these commands

  # Given a world hash and (optionally) a key to the world[:rooms]
  # hash, this method will initialize a State in which the player is
  # in the given room and current state of the world.  If no room is
  # given, world[:start_room] is used instead.
  def initialize world, room=nil
    @world = world

    if room
      @room = world[:rooms][room]
    else
      @room = world[:rooms][world[:start_room]]
    end

    puts @room[:desc]
  end

  set_cmd_help :look, "\t\t\t --  look around the room for items, exits, etc."

  # Allows the player to look at the room's description, the current
  # items in the room, and the available exits to other rooms.
  def cmd_look
    puts @room[:desc]

    # Print items
    if @room[:items] and not @room[:items].empty?
      puts " Items within reach:"
      print_indented @room[:items]
    end
    
    # Print exits
    puts " You see the following exits:"
    print_indented(@room[:exits].map do |dir, room_key|
                     room = @world[:rooms][room_key]
                     dir.to_s + " (" + room[:name] + ")"
                   end)
    self # No change in the game's State
  end

  set_cmd_help :go, "<dir>\t\t --  go through the exit in the given direction"

  # Given a direction (optionally), takes the player to corresponding
  # if it exists.  If no such direction exists or no direction is
  # given, a helpful notification will display to the user.
  def cmd_go direction=nil
    if not direction
      puts "Go where???"
      self
    elsif not @room[:exits][direction.to_sym]
      puts "No such place to go! (Maybe you should look around for an exit!)"
      self
    else
      newroom = @room[:exits][direction.to_sym]
      move_to_room @world, newroom
    end
  end

  set_cmd_help :take, "<item>\t\t --  take the item and put it in the inventory"

  # Allow the player to take an item (with the given item_tag) from
  # the room and place it in their inventory.  If no such item with
  # the item_tag exists or no item_tag is passed, a helpful
  # notification will display to the user.
  def cmd_take item_tag=nil
    if not item_tag
      puts "Take what???"
      return self
    end

    when_detected @room[:items], item_tag do |item|
      @world[:inventory] ||= [] # To deal with nils
      @world[:inventory].push item
      @room[:items].delete item
      
      puts "You grabbed the " + item_tag
      return self  
    end

    # No item found...
    puts "No such item..."
    self
  end
end




## TODO: Your FightState class and related Entity subclasses should go here ####

#class for all Enemys in the game
class Enemy < Entity
  def initialize(health, attack_range, defense, name)
    @health = health #health of the enemy
    @attack_range = attack_range # enemys attack range
    @defense = defense #enemys set defense
    @gold = 0 #all enemys drop gold
    super name
  end
  
  attr_reader :health, :defense, :gold
  attr_writer :health
  
  # chooses a random attack from between the attack range
  def damage
    rand(@attack_range)
  end
end

# A Goblin enemy
class Goblin < Enemy
  GOBLIN_MAX = 10 #goblin max health
  GOBLIN_GOLD = 5 #goblin's gold
  def initialize(attack_range, defense, name)
    super(GOBLIN_MAX, attack_range, defense, name)
    @gold = GOBLIN_GOLD
  end
  
  def max_health
    GOBLIN_MAX
  end
end

# A Zombie enemy
class Zombie < Enemy
  ZOMBIE_MAX = 15 #zombie max health
  ZOMBIE_GOLD = 7 #zombie gold
  def initialize(attack_range, defense, name)
    super(ZOMBIE_MAX, attack_range, defense, name)
    @gold = ZOMBIE_GOLD
  end

  def max_health
    ZOMBIE_MAX
  end
end

# A Werewolf enemy
class Werewolf < Enemy
  WEREWOLF_MAX = 20 #werewolf max health
  WEREWOLF_GOLD = 10 #werewolf's gold
  def initialize(attack_range, defense, name)
    super(WEREWOLF_MAX, attack_range, defense, name)
    @gold = WEREWOLF_GOLD
  end
  
  def max_health
    WEREWOLF_GOLD
  end
end

# class for all the weapons
class Weapon < Entity
  def initialize(name,price,attack_range)
    @attack_range = attack_range # weapons attack range
    # for the case when the are equipped as armor
    @defense = 0 
    @price = price # how much a weapon costs
    @heal_affect = 0 #for if used as healing
    super name
  end
  
  # chooses a random attack from attack range
  def damage
    rand(@attack_range)
  end
  
  attr_reader :defense, :heal_affect, :price, :attack_range

end



# A Sword Weapon
class Sword < Weapon
  def initialize(name,price,attack_range)
    super(name,price,attack_range)
  end

  def description
    puts "Strike enemys down with your Playskool"
    puts "toy sword.  You are on you way to being"
    puts "a big kid"
    puts "Attack Range: +#{attack_range}"
  end
end

# A Crossbow Weapon
class Crossbow < Weapon
  def initialize(name,price,attack_range)
    super(name,price,attack_range)
  end

  def description
    puts "used in the medieval days. May not"
    puts "be very useful in the 21st century"
    puts "you know..."
    puts "Attack Range: +#{attack_range}"
  end
end

# A class for Armor items
class Armor < Entity
  def initialize(name, price, defense)
    @damage = 0 # for case when equipped as weapon
    @price = price # price of armor
    @defense = defense # set defense for weapon
    @heal_affect = 0 # for if used as healing
    super name
  end
  
  attr_reader :defense, :damage, :price, :heal_affect
end

# A Shield Armor
class Shield < Armor
  def initialize(name,price,defense)
    super(name,price,defense)
  end

  def description
    puts "A simple shield. BORING!"
    puts "Defense Rating: +#{defense}"
  end
end

# A Helmet Armor
class Helmet < Armor
  def initialize(name,price,defense)
    super(name,price,defense)
  end
  def description
    puts "Basically just a baseball hat!"
    puts "Dont get too bold"
    puts "Defense Rating: +#{defense}"
  end
end


      
      
# A class which handles fighting
class FightState 
  include SystemState
  include PlayerState  # need to access players moves
  
  def initialize(world, room)
    @world = world
    @room = room
    @energy = 10 #determines if you can use moves or not
    puts "You have been ambushed!"
    cmd_enemies
  end
 
  set_cmd_help :enemies, "\t\t --  Shows the enemies in the current room"

  # prints out all enemies in room including there health
  def cmd_enemies
    print_indented(@world[:rooms][@room][:enemies].map {|x| "#{x.to_s}" + "(#{x.health})"})
    self
  end
  
 
                                                            
  set_cmd_help :attack, "<enemy>\t --  attack a certain enemy in the room"
  
  # allows user to attack an enemy
  def cmd_attack(enemy=nil)
    if enemy #if user typed an enemy to attack
      if @energy >= 3 #if user can attack
        @energy -= 3
        # checks if enemy is in the room
        result = when_detected(@world[:rooms][@room][:enemies], enemy) do |x|
          # checks if there is anything equipped and if weapon is equipped
          if @world[:equipped] and @world[:equipped][:weapon]
            damage = @world[:equipped][:weapon].damage
            puts "You used #{@world[:equipped][:weapon]} to do #{damage} damage to #{x}"
            x.health -= damage
          else # nothing equipped
            damage = rand(2)
            puts "You tried to attack with your fists and did #{damage} damage"
            x.health -= damage
          end
          #checks if enemy is dead
          if x.health <= 0
            puts "You have killed #{x.to_s} congratulations!"
            puts "#{x} dropped #{x.gold} gold and you took it"
            @world[:gold] += x.gold
            @world[:rooms][@room][:enemies].delete(x)
          else
            puts "#{x} has #{x.health} health left"
          end
          #checks if all enemys are dead
          if @world[:rooms][@room][:enemies].empty?
            puts "Congrats you have won this battle!"
            return RoomState.new(@world,@room)
          else
            #checks if anything equipped and armor equipped
            if @world[:equipped] and @world[:equipped][:armor]
              enemy_attack(@world[:equipped][:armor].defense)
            else  #nothing equipped
              enemy_attack
            end
            
            #checks if user died
            if @world[:health] <= 0
              return FailureState.new
            end
            puts "You have #{@world[:health]} health left"
          end
          self
        end
        
        #if given enemy is not in the room
        if result == nil
          puts "No such enemy found.  Please pick one of the following enemies to attack:"
          cmd_enemies
        end
        
      else  #user cannot fight
        puts "You do not have enough energy to fight! Try defending"
      end
    else #user did not specify enemy
      puts "Attack What?"
      cmd_enemies
    end
    self
  end
  
 
  
  #helper which allows enemys to counterattack
  def enemy_attack(amount = 0)
    @world[:rooms][@room][:enemies].each {|enemy| 
      damage = enemy.damage - amount
      if damage < 0
        damage = 0
      end
      @world[:health] -= damage
      puts "#{enemy} attacked you and did #{damage} damage to you"}
  end
  
  set_cmd_help :defend, "\t\t --  defend against the enemies in the room"

  #allows user to defend and heal energy
  def cmd_defend
    @energy += 2 #restores user energy
    #if anything equipped and armor equipped
    if @world[:equipped] and @world[:equipped][:armor]
      puts "You are defending with #{@world[:equipped][:armor]}"
      enemy_attack(@world[:equipped][:armor].defense)
    else #nothing equipped
      puts "You have nothing to defend with and are wide open for any attacks!"
      enemy_attack
    end
    #check if user died from enemy attack
    if @world[:health] <= 0
      return FailureState.new
    else
      self
    end
  end
end



####  End of YOUR ADVENTURE GAME code. #########################################

# The first game state entered by the game.  This allows the player to
# select a game world or quit without doing anything.
class MainMenuState
  # As all good state classes must, include the SystemState module.
  include SystemState

  # The hash of available worlds for the player.  Worlds are defined
  # at the end of th file so that they don't clutter the code here.
  @@worlds = {}

  # Print a welcome message for the user and explain the menu.
  def initialize
    puts "Welcome to the 341 adventure game!"
    puts "I'm your host, the MainMenu!"
    puts
    cmd_help
  end

  set_cmd_help :play, "<world>\t\t --  start a new game"

  # If given a valid world name in $worlds, return the initial game
  # state (a RoomState) for that world.  Otherwise, tell the user
  # about any invalid world given and run the worlds command.
  def cmd_play world_name=nil
    return cmd_worlds if not world_name

    world = @@worlds[world_name]
    if not world
      puts "No such world: " + world_name
      cmd_worlds
    else
      # Introduce world and start in initial room
      puts "Welcome to the world of " + world[:long_name] + "!!!"
      puts "------------------------"
      puts world[:desc]
      puts
      RoomState.new(world.clone) # Copy world definition for mutation protection
    end
  end

  set_cmd_help :worlds, "\t\t --  list all available worlds to play"

  # Simply print out the available worlds to play without changing the
  # game state.
  def cmd_worlds
    puts "The available worlds:"
    print_indented @@worlds.keys
    self
  end
end

# The main class for playing the adventure game.  Simply has a play
# method that'll start up the interactive game REPL.
class Adventure
  def play
    state = MainMenuState.new
    until state.finished?
      print "Enter a command: "
      command = gets.split "\s"
      if not command.empty?
        cmd_name = "cmd_"+command[0]
        cmd_args = command[1..-1]
        puts
        # Send command to current state with its arguments.  Retrieve
        # next game state and save it for next command.
        # Commands will be sent any number of arguments that the
        # player enters all as strings.
        begin
          state = state.send cmd_name, *cmd_args
        rescue ArgumentError => e
          # Check for a player mistake (i.e. they gave a wrong number
          # of arguments to a command)
          if e.backtrace.first =~ /`#{cmd_name}'$/
            # Treat player mistake as an invalid command.
            state.method_missing cmd_name, *cmd_args
          else
            # Otherwise, it's a real exception and should be punted
            raise e
          end
        end
      end
    end

    # On a finished state, print the results for the player and end
    # the REPL.
    state.print_result
  end
end

# Add to the worlds available.
class MainMenuState
  @@worlds["TestGame1"] = { # This defines a world labeled "TestGame1"
    :long_name => "Test World Number 1", # A long name to describe the world
    :desc => "A simple test world with all the right stuff!", # Worlds description
    :health => 20,# The player's starting health in this world,
    :gold => 50, # Player's starting gold
    :start_room => :room1, # The room to first place the player
    :final_room => :room4, # The goal room for the player to reach
    :rooms => { # A hash from room id's to their details
      :room1 => { # A room with :room1 as its id
        :name => "Central Room", # The room's name
        :desc => "This is an empty room with nothing in it.", # Room description
        :exits => { # Hash from exit id's to room id's
          :north => :room3,
          :south => :room2}},
      :room2 => {
        :name => "Armory",
        :desc => "You see a room filled with items (that are mostly out of reach)!",
        :items => [Sword.new("sword", 0, 25), Crossbow.new("crossbow",0, 10), Shield.new("shield", 0, 5)],  # An enum of items that can be picked up

        :exits => {
          :north => :room1}},
      :room3 => {
        :name => "Enemy battle",
        :desc => "A deadly test room with deadly, deadly enemies.",
        :enemies => [Goblin.new(8,5,"goblin"), Zombie.new(6,4,"zombie"), Werewolf.new(5,7, "werewolf")],  # An enum of enemies in wait in this room
        :exits => {
          :south => :room1,
          :north => :room4}},
      :room4 => { # A simple room meant for ending the game
        :name => "Victory Room",
        :desc => "You reached the end of your journey."}}}
end


############ EXTRA CREDIT ###################################################
class RoomState
  
  set_cmd_help :info, "<item> \t\t --  Get the info of a item in the room"

 #allows the user to check the info of an item
  def cmd_info(item)
    if @room[:items]
      result = when_detected(@room[:items], item)  { |x| 
        puts "#{x.description}"
        puts ""
        self}
      if result == nil # didnt find item in shop
        puts "No such item. Please enter one of the following:\n"
        print_indented(@room[:items])
      end
    else
      puts "You have no items to get info off"
    end
    self
  end
end
  
# A Curried Sword Weapon
class CurriedSword < Weapon
  def initialize(name,price,attack_range)
    super(name,price,attack_range)
  end

  def description
    puts "The MUPL-Land adventurer's most trusted weapon ... "
    puts "separates enemies into many parts!"
    puts "Attack Range: +#{damage}"
  end
end

# A Poisoned Fork Weapon
class PoisonedFork < Weapon
  def initialize(name,price,attack_range)
    super(name,price,attack_range)
  end

  def description
    puts "You see a dirty fork with leftover spaghetti sauce on it"
    puts "Enemies tremble before germs!!"
    puts "Attack Range: +#{attack_range}"
  end
end

# A Flavored Floss Weapon
class FlavoredFloss < Weapon
  def initialize(name,price,attack_range)
    super(name,price,attack_range)
  end

  def description
    puts "Cavaties beware! A weapon used to take out whats"
    puts "between the spaces and a little minty flavor makes"
    puts "it even more scarier!"
    puts "Attack Range: +#{attack_range}"
  end
end

class Napkin < Armor
  def initialize(name,price,defense)
    super(name,price,defense)
  end

  def description
    puts "Clean your self off of wounds with a nice"
    puts "soft sturdy napkin!"
    puts "Defense rating: +#{defense}"
  end
end

# A Febreeze Weapon
class Febreeze < Weapon
  def initialize(name,price,attack_range)
    super(name,price,attack_range)
  end

  def description
    puts "Clean out all your enemies with with this weapon ... "
    puts "Lemon-scented for your olfactory pleasure!"
    puts "Damage rating: +#{damage}"
  end
end

# A Closure Cape Armor
class ClosureCape < Armor
  def description
    puts "Keeps you *functioning* in your current environment ... "
    puts "May be useful against Hal Monster *double wink*"
    puts "Defense rating: +#{defense}"
  end
end

# A Thunk Shield Armor
class ThunkShield < Armor
  def initialize(name,price,defense)
    super(name,price,defense)
  end

  def description
    puts "Hide behind a lambda so no one can touch you!"
    puts "Defense rating: +#{@defense}"
  end
end

# a class for all Items
class Item < Entity
  def initialize(name, price)
    @price = price
    @heal_affect = 0 #for used as healing
    @damage = 0 #for used as a weapon
    @defense = 0 #for used as an armor
    super name
  end
  
  attr_reader :price, :heal_affect, :damage, :defense
end

# a class for a KitKat item
class KitKat < Item
  def initialize(name,price)
    super(name,price)
  end

  def description
    puts ""
    puts "Luscious wafer center coated in dilectible layer"
    puts "of creamy milk chocolate. May be useful against Cody Monster *wink*"
  end
end

# a class for a String Cheese item
class StringCheese < Item
  def initialize(name,price)
    super(name,price)
  end

  def description
    puts "Stringy goodness!"
  end
end

#a class for a Potion item
class Potion < Item
  def initialize(name, price)
    super(name, price)
    @heal_affect = 15
  end

  def description
    puts ""
    puts "1 part vodka, 1 part gin, and 1 part rum ... "
    puts "This MUPLICIOUS elixir will add 15 to your health!"
  end
end

# a class for a Ruby Oracle item
class RubyOracle < Item
  def initialize(name,price)
    super(name,price)
  end

  def description
    puts "Useful when encountering James the Break-Dancing Wizard *wink*"
  end
end
  
#a class for a SchemeSceptor item
class SchemeSceptor < Item
  def initialize(name,price)
    super(name,price)
  end

  def description
    puts ""
    puts "Usefuly when encountering Tim the Salsa-Dancing Wizard *wink*"
  end
end

# a George enemy
class George < Enemy
  GEORGE_MAX = 10 #max health
  GEORGE_GOLD = 10 #george's gold
  def initialize(attack_range,defense, name)
    super(GEORGE_MAX,attack_range,defense,name)
    @gold = GEORGE_GOLD #george's gold
  end
  
  # returns George's max health
  def max_health
    GEORGE_MAX
  end
end

# a martha enemy
class Martha < Enemy
  MARTHA_MAX = 10 #max health
  MARTHA_GOLD = 10 #martha's gold
  def initialize(attack_range,defense,name)
    super(MARTHA_MAX, attack_range, defense, name)
    @gold = MARTHA_GOLD
  end
  
  #returns martha's max health
  def max_health
    MARTHA_MAX
  end
end

# creates a Cody Monster
class CodyMonster < Enemy
  CODY_MAX = 100
  def initialize(attack_range, defense, name)
    @defenses_lowered = false
    super(CODY_MAX, attack_range, defense, name)
  end
  attr_accessor :defenses_lowered
  attr_writer :health
end

# creates new CodyState which adds the feed ability
class CodyState < FightState
  
  def initialize(world, room)
    @cody_monster = world[:rooms][room][:enemies][0]
    super(world, room)
    print_results
  end

  def print_results
    puts "Defeat the evil and ruthless Cody Monster to continue"
    puts "on your journey through MUPL-Land!"
  end

  set_cmd_help :feed, "\t\t   -- feed item to Cody"
  
  def cmd_feed(item)
    result = when_detected(@world[:inventory], item) { |x| 
      if x.to_s == "KitKat"
        puts "You handfed Cody Monster a KitKat."
        puts "his defenses will be lowered as he's nom-noming"
        puts "on his tasty treat! Attack swiftly!"
        @cody_monster.health = 1
      else
        puts "That item is in your inventory but"
        puts "cannot be fed to Cody Monster :("
        true
      end}
    if result == nil
      puts "Not a valid item in inventory"
    end
    self
  end
  
end
# A Salsa Entity
class Salsa < Entity
  def initialize(name, damage, mana)
    @damage = damage # how much damage it can do
    @mana = mana # how much energy it costs
    super name
  end
  
  attr_reader :mana
  
  # description of what it does
  def description
    puts "Your impressive salsa moves shocks the enemies"
    puts "and creates a tornado whirling toward all your"
    puts "enemies"
  end
    
  def damage
    # chooses random attack from damage
    damage = rand(@damage)
  end
end

# A Break Entity
class Break < Entity
  def initialize(name, damage, mana)
    @damage = damage # how much damage it can do
    @mana = mana # how much energy it costs
    super name 
  end
  
  attr_reader :mana
 
  # description of what it does
  def description
    puts "Your rad breakdancing blows the enemies away"
    puts "However your moves are so awesome that they may"
    puts "also be potentially dangerous!"
  end
  
  # could damage user or enemy
  def damage
    will_attack = rand(4) # 25% chance of attacking user
    if will_attack == 0
      false
    else
      # chooses random attack from damage
      damage = rand(@damage)
    end
  end
end

# extends FightState to add enery, heal, and ability commands
class FightState
   set_cmd_help :energy, "\t\t --  Displays your current energy to fight"
  
  # displays current energy
  def cmd_energy
    puts "You have #{@energy} left"
    self
  end
  
  # allows user to heal with item
  set_cmd_help :heal, "<item>\t\t --  heals you with certain item"

  def cmd_heal(item)
    # check if item is in inventory
    result = when_detected(@world[:inventory], item) {|x| 
      if x.heal_affect > 0 #check if item can heal
        puts "You consumed #{x} and it gave you #{x.heal_affect} health"
        @world[:health] += x.heal_affect
      else
        puts "You consumed #{x} and it had no effect"
      end}
    if result == nil #did not find item in inventory
      puts "You do not have that item to heal with in your inventory"
    end
    self
  end

 set_cmd_help :use_ability, "<ability>\t --  use an ability"
  
  #allows user to use ability
  def cmd_use_ability(ability=nil)
    if ability #ability specified
      if @world[:abilities] #abilities exists
        #checks if given ability is a ability
        result = when_detected(@world[:abilities],ability) {|x|
          # if user has enough energy to use ability
          if @energy >= x.mana
            @energy -= x.mana
            x.description
            @world[:rooms][@room][:enemies].each {|enemy|
              attack = x.damage
              # checks if user attacks himself or not
              if attack
                puts "You did #{attack} damage to #{enemy.to_s}"
                enemy.health -= attack
              else #user attacks himself
                puts "Your ability backfired and you damaged yourself"
                @world[:health] -= 3
              end
              # checks if enemy is killed
              if enemy.health <= 0
                puts "You have killed #{enemy.to_s} congratulations"
                puts "#{enemy} dropped #{enemy.gold} gold and you took it!"
                @world[:gold] += enemy.gold
                @world[:rooms][@room][:enemies] = 
                  @world[:rooms][@room][:enemies].reject {|killed|
                  killed == enemy}
              else #enemy still alive
                puts "#{enemy.to_s} has #{enemy.health} health left"
              end
              #checks if user killed himself from move
              if @world[:health] <= 0
                return FailureState.new
              end}
            if @world[:rooms][@room][:enemies].empty?
              puts "Congrats you have won this battle!"
              return RoomState.new(@world,@room)
            else
              enemy_attack
            end
          else #user cannot use ability
            puts "You do not have enough energy to use this ability"
          end}
        #ability not found
        if result == nil
          puts "You do not have that ability to use"
        end
      else #no abilities exist
        puts "You do not have any abilities to use"
      end
    else #user did not specify
      if @world[:abilities] #if abilities exist
        puts "Use what ability?"
        print_indented(@world[:abilities])
      else
        puts "You do not have any abilities to use"
      end
    end
    self
  end
end

#class which handles being Enlightened for first time
class EnlightendStateJames < RoomState
  include PlayerState
  
  def initialize(world,room)
    super(world,room)
    @world[:health] += 20  #restores 20 health to user
    @use_talk = true  #determines if can use talk
    @use_dance = true #determines if can use dance
    @use_advice = true #determines if can use advice
    puts "You enter a room with blasting awesome hip-hop music."
    puts "Somehow you suddenly feel relaxed and have a sudden urge to"
    puts "dance and program.  A break dancing, programming wizard"
    puts "approaches you.  What will you do?"
  end
  
  set_cmd_help :talk, "\t\t--  talk to the strange dancing wizards"
  
  # allows user to talk to the wizard
  def cmd_talk
    if @use_talk
      puts "James, the wise break dancing wizard asks you"
      puts "QUICK! What kind of type is programming language SML?"
      puts "a: rock type"
      puts "b: dynamic type"
      puts "c: static type"
      puts "d: awesome type"
      move = gets.chomp
      if move == "c"
        puts "That is correct.  James blew your mind away with an"
        puts "impressive dance move and gave you 20 gold and an item"
        @use_talk = false #cant use talk anymore
        @world[:gold] += 20
        @world[:inventory].push("potion",0,7)
      else
        puts "That is incorrect.  James attacked you with his break dancing"
        puts "move and damaged you for 10 health"
        @world[:health] -= 10
        #checks if user died
        if @world[:health] <=0
          return FailureState.new
        end
      end
    else
      puts "You cannot talk to the wizard anymore"
    end
    self
  end
  
  set_cmd_help :get_advice, "\t\t --  get advice from the wise wizard"

  #allows user to ask advice
  def cmd_get_advice
    if @user_advice
      puts "You ask the wise breakdancing wizard for"
      puts "advice on how to survive the perils of MUPL-Land"
      puts "However, in return for this valuable piece of advice"
      puts "the wizard asks for an oracle in return."
      puts ""
      puts "Would you like to give it an oracle? (y/n)"
      move = gets.chomp.downcase
      if move === "y"
        # checks if inventory exists
        if @world[:inventory]
          #checks if item is in inventory
          if @world[:inventory].include?("ruby_oracle")
            @use_advice = false #cant use advice anymore
            @world[:inventory].delete("ruby_oracle")
            puts "The wizard danced in ecstacy and gave you"
            puts "a helpful piece of advice."
            puts ""
            puts "The evil lurking Cody in MUPL-Land likes"
            puts "candy bars. But when you do see him just"
            puts "remember to just *give him a break* :)"
            puts ""
          else #not in inventory
            puts "Too bad you do not have ruby oracle"
            puts "you may be able to buy one at the shop"
            puts ""
          end
        end
      else #user types no
        puts "You cant get everything for free you know!"
        puts ""
      end
    else
      puts "You cannot get advice anymore"
    end
    self
  end
  
  set_cmd_help :break_dance, "\t\t --  Try to dance with the wizard"
  
  #allows user to dance with the user
  def cmd_break_dance
    if @use_dance
      puts "You tried to break it down with James but while you"
      puts "are dancing James tries to test your programming skills"
      puts "and asks you"
      puts "What does it mean for a type system to be sound"
      puts "a: it plays awesome dancing music"
      puts "b: never accepts something it is supposed to prevent"
      puts "c: never rejects something that cant do something its supposed to prevent"
      puts "d: it will play you an awesome song on the guitar"
      move = gets.chomp.downcase
      if move == "b"
        @use_dance = false #cant use dance anymore
        puts "Totally rad, you got that right!.  James taught you"
        puts "a secret dancing move"
        if not @world[:abilites] #checks if abilities exist
          @world[:abilities] = []
        end
        @world[:abilities].push(Break.new("break_dance",20,3))
      else #answer was wrong
        puts "That is incorrect. James did a hip twist move"
        puts "and blew you away"
        @world[:health] -= 10
        #checks if user dies
        if @world[:health] <= 0
          return FailureState.new
        end
      end
    else
      puts "You cannot dance anymore"
    end
    self
  end
end

# tim enlightened state
class EnlightendStateTim < RoomState
  def initialize(world,room)
    super(world,room)
    @world[:health] += 20  #restores 20 health to user
    @use_talk = true #determines if can use talk
    @use_dance = true #determines if can use dance
    @use_advice = true #determines if can use advice
    puts "You enter a room with soathing salsa music resonating throughout"
    puts "the room.  Somehow you suddently feel relaxed and have a sudden"
    puts "urge to dance and program.  A salsa dancing programming wizard"
    puts "glides over to you.  What do you do?"
  end
  
  set_cmd_help :talk, "\t\t--  talk to the dancing wizard"
  
  def cmd_talk
    if @use_talk
      puts "The salsa dancing wizard approaches you and starts"
      puts "speaking spanish to you.  Your vast skills in being an"
      puts "adventurer makes you understand him.  The wizard asks"
      puts "you in Spanish:"
      puts "What programming language is Ruby?"
      puts "a: A pokemon game"
      puts "b: A precious gem"
      puts "c: Object oriented"
      puts "d: the best language ever"
      move = gets.chomp.downcase
      if move == "c"
        puts "Muy Bien!! that is right.  Tim gave you 20 gold"
        @world[:gold] += 20
        @use_talk = false #cant use talk
      else
        puts "Incorrect.  Tim blasted you with a salsa move :("
        @world[:health] -= 10
      end
    else
      puts "You cannot talk to the wizard"
    end
    self
  end

  set_cmd_help :get_advice, "\t\t-- ask the wizard for advice"
  
  def cmd_get_advice
    if @user_advice
      puts "You try to stop the dancing wizard for one second"
      puts "to ask him a question, but the wizard will not stop"
      puts "However his magical powers allows him to talk and dance"
      puts "at the same time. AMAZING!.  Before he gives you"
      puts "valuable piece of advice you must give him a Sceme Scepter"
      puts "Will you give him that (y/n)"
      move = gets.chomp.downcase
      if move == "y"
        # checks if inventory exists
        if @world[:inventory]
          #checks if item is in inventory
          if @world[:inventory].include?("scheme_scepter")
            @use_advice = false #cant use advice
            @world[:inventory].delete("scheme_scepter")
            puts "The wizard was so happy he spoke in English"
            puts "for the first time! He said to you"
            puts "here is a helpful piece of advice."
            puts ""
            puts "When faced with the final test remember"
            puts "to wear a cape and *close your* mind to"
            puts "the evils of the enemy :)"
            puts ""
          else #not in inventory
            puts "Too bad you do not have saphire scepter"
            puts "you may be able to buy one at the shop"
            puts ""
          end
        end
      else #user types no
        puts "You cant get everything for free you know!"
        puts ""
      end
    else
      puts "You cannot get advice from the wizard"
    end
    self
  end
        
  set_cmd_help :dance, "\t\t--  dance with the wizards"
  def cmd_salsa_dance
    if @use_dance
      puts "You tried to dance with Tim, the salsa dancing wizard"
      puts "but he complains that you keep doing the same move."
      puts "He asks you, what kind of move should come after an"
      puts "open break?"
      puts "a: cross-body lead"
      puts "b: half-turn"
      puts "c: under-arm turn"
      puts "d: double spin"
      move = gets.chomp
      if move == "d"
        puts "That is correct. You've learned the ability to salsa dance."
        puts "BUT WAIT! Tim also blew your mind away with an awesome"
        puts "dance move and gave you 125 gold.  Lucky guy!"
        if not @world[:abilities]
          @world[:abilities] = []
        end
        @world[:abilities].push(Salsa.new("salsa_dance",15,5))
      else
        puts "That is incorrect.  Tim was fortunate enough to let"
        puts "you off the hook.  But was frustrated and did a double"
        puts "spin angrily away from you"
      end
    else
      puts "You cannot dance anymore"
    end
    self
  end
end

#class for a shop
class ShopState < RoomState
  def print_results
    puts "Welcome to the Merchant Shop!"
  end

  set_cmd_help :browse, "\t\t -- take a look at available items"
  #allows user to browse the items in the store
  def cmd_browse
    puts "The following items are available for purchase ... "
    puts "Type   info (item)  for a closer look!"
    print_indented(@room[:products])
    self
  end
  
  set_cmd_help :info, "<item> \t\t -- get info for specific item" 

  #allows the user to check the info of an item
  def cmd_info(item)
    result = when_detected(@room[:products], item)  { |x| 
      puts "#{x.description}"
      puts "Price: #{x.price} cdrs" 
      puts ""
      true}
    if result == false # didnt find item in shop
      puts "No such item. Please enter one of the following:\n"
      print_indented(@room[:products])
    end
    self
  end

  set_cmd_help :purchase, "<item>\t -- add item to inventory"

  #allows the user to purchase an item
  def cmd_purchase(item)
    #checks whether given item is in the shop
    result = when_detected(@room[:products], item) { |x| 
      if @world[:gold] >= x.price #checks if user has enough money
        puts "#{x.to_s} purchased for #{x.price} gold!"
        @world[:gold] -= x.price
        @room[:products].delete(x)
        @world[:inventory].push(x)
      else
        puts "You do not have enough gold to purchase this item!"
      end}
    if result == false #item not found in shop
      puts "No such item. Please enter one of the following:\n"
      print_indented(@room[:products])
    end
    self
  end
end

# training room where you can practice fighting skills
class TrainingState < FightState
  def initialize(world,room)
    super(world,room)
    puts @world[:rooms][@room][:desc]
  end
  
  def cmd_attack(enemy=nil)
    if enemy #if user typed an enemy to attack
      if @energy >= 3 #if user can attack
        @energy -= 3
        # checks if enemy is in the room
        result = when_detected(@world[:rooms][@room][:enemies], enemy) do |x|
          # checks if there is anything equipped and if weapon is equipped
          if @world[:equipped] and @world[:equipped][:weapon]
            damage = @world[:equipped][:weapon].damage
            puts "You used #{@world[:equipped][:weapon]} to do #{damage} damage to #{x}"
            x.health -= damage
          else # nothing equipped
            damage = rand(2)
            puts "You tried to attack with your fists and did #{damage} damage"
            x.health -= damage
          end
          #checks if enemy is dead, if it is revives it
          if x.health <= 0
            puts "You have killed #{x.to_s} congratulations!"
            puts "#{x} dropped #{x.gold} gold and you took it"
            @world[:gold] += x.gold
            x.health = x.max_health
          else
            puts "#{x} has #{x.health} health left"
          end
          #checks if anything equipped and armor equipped
          if @world[:equipped] and @world[:equipped][:armor]
            enemy_attack(@world[:equipped][:armor].defense)
          else  #nothing equipped
            enemy_attack
          end
          
          #checks if user died
          if @world[:health] <= 0
            return FailureState.new
          end
          puts "You have #{@world[:health]} health left"
          self
        end
        
        #if given enemy is not in the room
        if result == nil
          puts "No such enemy found.  Please pick one of the following enemies to attack:"
          cmd_enemies
        end   
      else  #user cannot fight
        puts "You do not have enough energy to fight! Try defending"
      end
    else #user did not specify enemy
      puts "Attack What?"
      cmd_enemies
    end
    self
  end
  
   def cmd_use_ability(ability=nil)
    if ability #ability specified
      if @world[:abilities] #abilities exists
        #checks if given ability is a ability
        result = when_detected(@world[:abilities],ability) {|x|
          # if user has enough energy to use ability
          if @energy >= x.mana
            @energy -= x.mana
            x.description
            @world[:rooms][@room][:enemies].each {|enemy|
              attack = x.damage
              # checks if user attacks himself or not
              if attack
                puts "You did #{attack} damage to #{enemy.to_s}"
                enemy.health -= attack
              else #user attacks himself
                puts "Your ability backfired and you damaged yourself"
                @world[:health] -= 3
              end
              # checks if enemy is killed, and if it is revives it
              if enemy.health <= 0
                puts "You have killed #{enemy.to_s} congratulations"
                puts "#{enemy} dropped #{enemy.gold} gold and you took it!"
                @world[:gold] += enemy.gold
                enemy.health = enemy.max_health #revives enemy
              else #enemy still alive
                puts "#{enemy.to_s} has #{enemy.health} health left"
              end
              #checks if user killed himself from move
              if @world[:health] <= 0
                return FailureState.new
              end}
          else #user cannot use ability
            puts "You do not have enough energy to use this ability"
          end}
        #ability not found
        if result == nil
          puts "You do not have that ability to use"
        end
      else #no abilities exist
        puts "You do not have any abilities to use"
      end
    else #user did not specify
      if @world[:abilities] #if abilities exist
        puts "Use what ability?"
        print_indented(@world[:abilities])
      else
        puts "You do not have any abilities to use"
      end
    end
    self
   end
   
   set_cmd_help :quit_training, " \t --  stop training"
   
   def cmd_quit_training
     RoomState.new(@world,@room)
   end
 end
 
# final room where you face Hal's extensive programming knowledge
class VictoryRoom < RoomState
  def initialize(world,room)
    super(world,room)
  end
  
  set_cmd_help :question, "\t\t -- ask your final question"

  def cmd_question
    puts "The creater of MUPL-Land Hal who is hidden"
    puts "in a deep thunk, and revealed himself with a set of"
    puts "parentathies.  He said *How dare you traverse my land and defeat"
    puts "my evil minion Cody.  I could probably defeat you by"
    puts "failing you, but that would be a waste of my effort."
    puts "Instead I will test your skills and see if you are worthy"
    puts "of becoming a MUPL-master.*"
    puts "WHAT ASPECT OF PROGRAMMING LANGUAGE IS THE CODE AND THE"
    puts "CURRENT ENVIRONMENT?"
    puts "a: theres nothing like that at all"
    puts "b: closure"
    puts "c: who cares"
    puts "d: a function"
    move = gets.chomp.downcase
    if move== "b"
      puts "Congratulations! You have learned well my young student"
      puts "You are one step closer to becoming a MUPL-master. Continue"
      puts "your journey and you will know what it is like to be master"
      puts "just like me"
      return VictoryState.new
    else
      puts "Shame on you!  If there was one thing I thought you learned"
      puts "From adventuring MUPL land was the answer to this question"
      puts "Hence, I fail you and ban you from the spoils of being a MUPL"
      puts "master. BETTER LUCK NEXT TIME!"
      return FailureState.new
    end
  end
end
  
  
class MainMenuState

 @@worlds["MUPL-Land"] = { # This defines a world labeled "MUPL-Land"
    :long_name => "MUPL-Land", # A long name to describe the world
    :desc => "A strange land where nothing makes sense and dangers abound!", # Worlds description
    :health => 50,  # The player's starting health in this world
    :gold => 20,  # The player's starting gold
    :inventory => [],
    :start_room => :start,# The room to first place the player
    :training_room => :training,
    :shop_room => :shop,
    :enlightend_room1 => :enlighten1,
    :enlightend_room2 => :enlighten2,
    :boss1 => :cody_boss,
    :victory => :victory_room, # The goal room for the player to reach
    :rooms => { # A hash from room id's to their details
      :start => { # A room with :room1 as its id
        :name => "Central Room", # The room's name
        :desc => "MUPL magic has transfered you to the starting room! Welcome!", # Room description
        :exits => { # Hash from exit id's to room id's
          :north => :enlighten1,
          :west => :training,
          :east => :shop,
          :south => :storage}},
      :shop => {
        :name => "Merchant Shop",
        :desc => "Welcome to the MUPL-Land curiosity shop!\n
We sell all sorts of interesting itmes ...\nfeel free to take a look around.\n",
        :products => [KitKat.new("KitKat", 10), Potion.new("potion", 7), CurriedSword.new("curried_sword", 15, 9), RubyOracle.new("oracle", 12), Febreeze.new("febreeze", 8, 15), ClosureCape.new("closure_cape", 5, 15), ThunkShield.new("thunk_shield", 3, 20)],
        :exits => {
          :west => :start}},
          
      :training => {
        :name => "A perfect training room",
        :desc => "Train yourself against an infinite stream of george and martha",
        :enemies => [George.new(7,2,"george"), Martha.new(6,2,"martha")],  # An enum of enemies in wait in this room
        :exits => {
          :east => :start}},
      :storage => {
        :name => "Dusty storage room",
        :desc => "You see a worn down room probably a storage room",
        :items => [Febreeze.new("febreeze",0,4), FlavoredFloss.new("flavored_floss",0,5), Napkin.new("napkin",0,5)],
        :exits => {
          :north => :start}}, 
      :enlighten1 => { # A simple room meant for ending the game
        :name => "Enlightenment Room",
        :desc => "",
        :exits => {
          :south => :start,
          :north => :cody_boss}},
      :enlighten2 => {
        :name => "Enlightenment Room 2",
        :desc => "",
        :exits => {
          :south => :cody_boss,
          :north => :victory_room}},
      :cody_boss => {
        :name => "Boss room with an evil Cody!",
        :desc => "You sense an evil presence lurking in the room",
        :enemies => [CodyMonster.new(20,1,"cody")],
        :exits => {
          :north => :enlighten2,
          :south => :enlighten1}},
      :victory_room => {
        :name => "Victory Room",
        :desc => "Your final test waits within",
        :exits => {
          :south => :enlighten2}}}}
end

Adventure.new.play
