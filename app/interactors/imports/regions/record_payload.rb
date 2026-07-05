require "digest"
require "json"

module Imports
  module Regions
    module RecordPayload
      module_function

      def raw(record)
        record.deep_stringify_keys
      end

      def normalized(record)
        {
          "name" => record[:name],
          "ascii_name" => record[:ascii_name],
          "region_kind" => record[:region_kind],
          "country_code" => record[:country_code],
          "parent_external_uid" => record[:parent_external_uid],
          "latitude" => record[:latitude],
          "longitude" => record[:longitude],
          "alternate_names" => Array(record[:alternate_names]).map(&:deep_stringify_keys)
        }
      end

      def checksum(raw_payload:, normalized_payload:)
        Digest::SHA256.hexdigest(
          JSON.generate(deep_sort_value("raw_payload" => raw_payload, "normalized_payload" => normalized_payload))
        )
      end

      def deep_sort_value(value)
        case value
        when Hash
          value.keys.sort.each_with_object({}) do |key, memo|
            memo[key] = deep_sort_value(value.fetch(key))
          end
        when Array
          value.map { |item| deep_sort_value(item) }
        else
          value
        end
      end
    end
  end
end
