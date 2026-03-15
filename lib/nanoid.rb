require "securerandom"

module Nanoid
  SAFE_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze

  def self.generate(size: 21, alphabet: SAFE_ALPHABET, non_secure: false)
    return non_secure_generate(size:, alphabet:) if non_secure
    return simple_generate(size:) if alphabet == SAFE_ALPHABET && SAFE_ALPHABET.size == 64

    complex_generate(size:, alphabet:)
  end

  private_class_method def self.simple_generate(size:)
    bytes = random_bytes(size)

    (0...size).reduce(+"") do |id, idx|
      id << SAFE_ALPHABET[bytes[idx] & 63]
    end
  end

  private_class_method def self.complex_generate(size:, alphabet:)
    alphabet_size = alphabet.size
    mask = (2 << Math.log(alphabet_size - 1) / Math.log(2)) - 1
    step = (1.6 * mask * size / alphabet_size).ceil

    id = +""

    loop do
      bytes = random_bytes(step)

      (0...step).each do |idx|
        byte = bytes[idx] & mask
        character = byte && alphabet[byte]

        next unless character

        id << character
        return id if id.size == size
      end
    end
  end

  private_class_method def self.non_secure_generate(size:, alphabet:)
    alphabet_size = alphabet.size

    size.times.reduce(+"") do |id|
      id << alphabet[(Random.rand * alphabet_size).floor]
    end
  end

  private_class_method def self.random_bytes(size)
    SecureRandom.random_bytes(size).bytes
  end
end
