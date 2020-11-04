# frozen_string_literal: false

module MerciDanke
  module Amazon
    # Data Mapper: Amazon product -> Product entity
    class ProductMapper
      def initialize(gateway_class = Amazon::Api)
        @gateway_class = gateway_class
        @gateway = @gateway_class.new
      end

      def find(poke_name, apikey)
        # data = all data
        data = @gateway.product_data(poke_name, apikey)
        build_entity(data['results'])
      end

      def build_entity(products)
        products.map do |product|
          DataMapper.new(product).build_entity
        end
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(product_detail)
          @data = product_detail
        end

        def build_entity
          MerciDanke::Entity::Product.new(
            id: nil,
            title: title,
            link: link,
            image: image,
            rating: rating,
            ratings_total: ratings_total,
            price: price,
            currency: currency
          )
        end

        def title
          @data['title']
        end

        def link
          @data['link']
        end

        def image
          @data['image']
        end

        def ratings_total
          @data['ratingsTotal']
        end

        def rating
          @data['rating']
        end

        def price
          @data['prices'][0]['price']
        end

        def currency
          @data['prices'][0]['currency']
        end
      end
    end
  end
end
