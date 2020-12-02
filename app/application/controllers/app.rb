# frozen_string_literal: true

require 'roda'
require 'slim'
require 'slim/include'

module MerciDanke
  # Web App
  class App < Roda
    plugin :flash
    plugin :all_verbs # allows DELETE and other HTTP verbs beyond GET/POST
    plugin :render, engine: 'slim', views: 'app/presentation/view_html'
    plugin :assets, css: 'style.css', path: 'app/presentation/assets'
    plugin :halt

    use Rack::MethodOverride # for other HTTP verbs (with plugin all_verbs)

    route do |routing|
      routing.assets # load CSS

      # GET /
      routing.root do
        color_name = ''
        type_name = ''
        habitat_name = ''
        low_h = ''
        high_h = ''
        low_w = ''
        high_w = ''

        session[:watching] ||= []

        result = Service::ListProducts.new.call(session[:watching])

        if result.failure?
          flash[:error] = result.failure
        else
          products = result.value!
          if products.none?
            flash.now[:notice] = 'Add a Amazon product to get started'
          end

          products.each do |product|
            session[:watching] = product.map{ |pro| pro.origin_id}
          end
        end

        if session[:watching].count > 40
          session[:watching] = session[:watching][0..39]
        end

        5.times do |num|
          break if Database::PokemonOrm.find(id: 5)

          pokemons = Pokemon::PokemonMapper.new.find((num + 1).to_s)
          SearchRecord::ForPoke.entity(pokemons).create(pokemons)
        end

        pokemon_all = SearchRecord::ForPoke.klass(Entity::Pokemon).all
        2.times do |num|
          break unless SearchRecord::For.klass(Entity::Product).all.length.zero?
          amazon_products = Amazon::ProductMapper.new.find(pokemon_all[num].poke_name, MerciDanke::App.config.API_KEY)
          amazon_products.map do |product|
            SearchRecord::For.entity(product).create(product)
          end
        end

        popularities = []
        pokemon_all.map do |pokemon|
          products = SearchRecord::For.klass(Entity::Product)
            .find_full_name(pokemon.poke_name)

          pokemon_pokemon = SearchRecord::ForPoke.klass(Entity::Pokemon)
            .find_full_name(pokemon.poke_name)

          popularities.push(Mapper::Popularities.new(pokemon_pokemon, products).build_entity)
        end

        viewable_pokemons = Views::PokemonsList.new(pokemon_all, color_name, type_name, habitat_name, low_h, high_h, low_w, high_w, popularities)
        view 'home', locals: { pokemons: viewable_pokemons }
      end

      routing.on 'plus_like' do
        routing.is do
          routing.get do
            color_name = ''
            type_name = ''
            habitat_name = ''
            low_h = ''
            high_h = ''
            low_w = ''
            high_w = ''
            poke_id = routing.params['poke_id']
            SearchRecord::ForPoke.klass(Entity::Pokemon).plus_like(poke_id)
            pokemon_all = SearchRecord::ForPoke.klass(Entity::Pokemon).all
            popularities = []
            pokemon_all.map do |poke|
              products = SearchRecord::For.klass(Entity::Product)
                .find_full_name(poke.poke_name)

              pokemon_pokemon = SearchRecord::ForPoke.klass(Entity::Pokemon)
                .find_full_name(poke.poke_name)

              popularities.push(Mapper::Popularities.new(pokemon_pokemon, products).build_entity)
            end

            viewable_pokemons = Views::PokemonsList.new(pokemon_all, color_name, type_name, habitat_name, low_h, high_h, low_w, high_w, popularities)
            view 'home', locals: { pokemons: viewable_pokemons }
          end
        end
      end

      routing.on 'type' do
        routing.is do
          routing.get do
            color_name = routing.params['color'].nil? ? '' : routing.params['color'].downcase
            type_name = routing.params['type'].nil? ? '' : routing.params['type'].downcase
            habitat_name = routing.params['habitat'].nil? ? '' : routing.params['habitat'].downcase
            low_h = routing.params['low_h'].nil? ? '' : (routing.params['low_h'].downcase).to_f * 10
            high_h = routing.params['high_h'].nil? ? '' : (routing.params['high_h'].downcase).to_f * 10
            low_w = routing.params['low_w'].nil? ? '' : (routing.params['low_w'].downcase).to_f * 10
            high_w = routing.params['high_w'].nil? ? '' : (routing.params['high_w'].downcase).to_f * 10

            hash = {
              :'color' => color_name,
              :'type_name' => type_name,
              :'habitat' => habitat_name,
              :'weight' => (low_w..high_w),
              :'height' => (low_h..high_h)
            }

            newhash = hash.select { |_key, value| value != '' }
            newnewhash = newhash.select { |_key, value| value != (0.0..0.0) }

            pokemon = SearchRecord::ForPoke.klass(Entity::Pokemon)
                .find_all_advances(newnewhash)

            popularities = []
            pokemon.map do |poke|
              products = SearchRecord::For.klass(Entity::Product)
                .find_full_name(poke.poke_name)

              pokemon_pokemon = SearchRecord::ForPoke.klass(Entity::Pokemon)
                .find_full_name(poke.poke_name)

              popularities.push(Mapper::Popularities.new(pokemon_pokemon, products).build_entity)
            end

            viewable_pokemons = Views::PokemonsList.new(pokemon, color_name, type_name, habitat_name, low_h, high_h, low_w, high_w, popularities)
            view 'home', locals: { pokemons: viewable_pokemons }
          end
        end
      end
      routing.on 'products' do
        routing.is do
          # GET /products/
          routing.post do
            # poke_name = routing.params['poke_name'].downcase
            poke_request = MerciDanke::Forms::SearchProduct.new.call(routing.params)
            product_show = Service::ShowProducts.new.call(poke_request)
            puts "3", product_show

            if product_show.failure?
              flash[:error] = product_show.failure
              routing.redirect '/'
            end
            poke_name = product_show.value!
            routing.redirect "products/#{poke_name}"
          end
        end

        routing.on String do |poke_name|
          # GET /products/poke_name, apikey
          routing.get do
            # Get pokemon and products from database
            begin
              pokemon_pokemon = SearchRecord::ForPoke.klass(Entity::Pokemon)
                .find_full_name(poke_name)
              SearchRecord::ForPoke.entity(pokemon_pokemon).create(pokemon_pokemon)
              amazon_products = SearchRecord::For.klass(Entity::Product)
                .find_full_name(poke_name)
              if amazon_products.length.zero?
                pokemon_pokemon = Pokemon::PokemonMapper
                  .new.find(poke_name)
                begin
                  amazon_products = Amazon::ProductMapper
                    .new.find(poke_name, MerciDanke::App.config.API_KEY)
                  amazon_products.map do |product|
                    SearchRecord::For.entity(product).create(product)

                    session[:watching].insert(0, product.poke_name).uniq!
                  end
                rescue StandardError
                  flash[:error] = 'Amazon products have some unknown problems. Please try again!'
                  routing.redirect '/'
                end
              end
            rescue StandardError
              flash[:error] = 'Having trouble accessing the database'
              routing.redirect '/'
            end

            viewable_products = Views::ProductsList.new(amazon_products, poke_name, pokemon_pokemon)
            view 'products', locals: { products: viewable_products }
          end

          routing.post do
            product_id = routing.params['product_id']
            SearchRecord::For.klass(Entity::Product).plus_like(product_id)
            amazon_products = SearchRecord::For.klass(Entity::Product)
              .find_full_name(poke_name)
            pokemon_pokemon = SearchRecord::ForPoke.klass(Entity::Pokemon)
              .find_full_name(poke_name)

            viewable_products = Views::ProductsList.new(amazon_products, poke_name, pokemon_pokemon)
            view 'products', locals: { products: viewable_products }
          end
        end
      end
    end
  end
end