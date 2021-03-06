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

      def self.find_all_advances(hash)
        if hash.key?(:'type_name')
          db_pokemons = Database::PokemonOrm
            .left_join(Database::TypeOrm.left_join(:pokemons_types, type_id: :id), poke_id: :id)
            .where(hash)
            .all
        else
          db_pokemons = Database::PokemonOrm
            .where(hash)
            .all
        end
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

      # update the num of poke_likes
      def self.plus_like(id)
        poke_like_num = Database::PokemonOrm.where(id: id).first.poke_likes
        Database::PokemonOrm.where(id: id).first.update(poke_likes: poke_like_num + 1)
      end

      def self.create(entity)
        db_new_pokemon = PersistPokemon.new(entity).call unless find(entity)
        rebuild_entity(db_new_pokemon)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

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
