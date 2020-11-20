# frozen_string_literal: true

module MerciDanke
  module SearchRecord
    # SearchRecord for Pokemon Entities
    class Pokemons
      def self.all
        Database::PokemonOrm.all.map { |db_pokemon| rebuild_entity(db_pokemon) }
      end

      def self.find_full_name(poke_name)
        # SELECT * FROM `projects` LEFT JOIN `members`
        # ON (`members`.`id` = `projects`.`owner_id`)
        # WHERE ((`username` = 'owner_name') AND (`name` = 'project_name'))
        db_pokemon = Database::PokemonOrm
          .where(poke_name: poke_name)
          .first
        rebuild_entity(db_pokemon)
      end

      def self.find_type(type_name)
        db_pokemons = Database::PokemonOrm
          .left_join(Database::TypeOrm.left_join(:pokemons_types, type_id: :id), poke_id: :id)
          .where(type_name: type_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_color(color_name)
        db_pokemons = Database::PokemonOrm
          .where(color: color_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_habitat(habitat_name)
        db_pokemons = Database::PokemonOrm
          .where(habitat: habitat_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_height(low, high)
        # SELECT * FROM clients WHERE (clients.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
        # Client.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
        low = low.to_f * 10
        high = high.to_f * 10
        db_pokemons = Database::PokemonOrm
          .where(height: (low..high))
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_weight(low, high)
        low = low.to_f * 100
        high = high.to_f * 100
        db_pokemons = Database::PokemonOrm
          .where(weight: (low..high))
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_color_and_type(color_name, type_name)
        db_pokemons = Database::PokemonOrm
          .left_join(Database::TypeOrm.left_join(:pokemons_types, type_id: :id), poke_id: :id)
          .where(color: color_name, type_name: type_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_color_and_habitat(color_name, habitat_name)
        db_pokemons = Database::PokemonOrm
          .where(color: color_name, habitat: habitat_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_type_and_habitat(type_name, habitat_name)
        db_pokemons = Database::PokemonOrm
          .left_join(Database::TypeOrm.left_join(:pokemons_types, type_id: :id), poke_id: :id)
          .where(type_name: type_name, habitat: habitat_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_height_and_type(low, high, type_name)
        db_pokemons = Database::PokemonOrm
          .left_join(Database::TypeOrm.left_join(:pokemons_types, type_id: :id), poke_id: :id)
          .where(height: (low..high), type_name: type_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_height_and_color(low, high, color_name)
        db_pokemons = Database::PokemonOrm
          .where(height: (low..high), color: color_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_height_and_habitat(low, high, habitat_name)
        db_pokemons = Database::PokemonOrm
          .where(height: (low..high), habitat: habitat_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_weight_and_type(low, high, type_name)
        db_pokemons = Database::PokemonOrm
          .left_join(Database::TypeOrm.left_join(:pokemons_types, type_id: :id), poke_id: :id)
          .where(weight: (low..high), type_name: type_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_weight_and_color(low, high, color_name)
        db_pokemons = Database::PokemonOrm
          .where(weight: (low..high), color: color_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_weight_and_habitat(low, high, habitat_name)
        db_pokemons = Database::PokemonOrm
          .where(weight: (low..high), habitat: habitat_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_height_and_weight(low, high, low_w, high_w)
        db_pokemons = Database::PokemonOrm
          .where(height: (low..high), weight: (low_w..high_w))
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find_type_and_color_and_habitat(type_name, color_name, habitat_name)
        db_pokemons = Database::PokemonOrm
          .left_join(Database::TypeOrm.left_join(:pokemons_types, type_id: :id), poke_id: :id)
          .where(type_name: type_name, color: color_name, habitat: habitat_name)
          .all
        db_pokemons.map do |db_pokemon|
          rebuild_entity(db_pokemon)
        end
      end

      def self.find(entity)
        find_origin_id(entity.origin_id)
      end

      def self.find_origin_id(origin_id)
        db_record = Database::PokemonOrm.first(origin_id: origin_id)
        rebuild_entity(db_record)
      end

      def self.create(entity)
        db_new_pokemon = PersistPokemon.new(entity).call unless find(entity)
        rebuild_entity(db_new_pokemon)
      end

      private

      def self.rebuild_entity(db_record)
        return nil unless db_record

        # db_record[:type] = JSON.parse(db_record[:type])

        MerciDanke::Entity::Pokemon.new(
          db_record.to_hash.merge(
            evochain: Evochains.rebuild_entity(db_record.evochain),
            abilities: Abilities.rebuild_many(db_record.abilities),
            types: Types.rebuild_many(db_record.types)
          )
        )
      end

      # Helper class to persist evochains and its abilities to database
      class PersistPokemon
        def initialize(entity)
          @entity = entity
        end

        def create_pokemon
          entity_hash = @entity.to_attr_hash
          # entity_hash[:type] = entity_hash[:type].to_s
          Database::PokemonOrm.create(entity_hash)
        end

        def call
          evochain = Evochains.db_find_or_create(@entity.evochain)
          create_pokemon.tap do |db_pokemon|
            db_pokemon.update(evochain: evochain)

            @entity.abilities.each do |ability|
              db_pokemon.add_ability(Abilities.db_find_or_create(ability))
            end
            @entity.types.each do |type|
              db_pokemon.add_type(Types.db_find_or_create(type))
            end
          end
        end
      end
    end
  end
end