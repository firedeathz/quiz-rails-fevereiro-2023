# frozen_string_literal: true

# HasBarcode
module HasBarcode
  extend ActiveSupport::Concern

  included do
    after_create :generate_barcode, if: -> { File.exist?(Rails.root.join("public/barcodes/appointments/a#{id}.png")) }

    # get barcode for receipt
    def generate_barcode
      require 'barby/barcode/code_128'
      require 'barby/outputter/png_outputter'

      dir = File.dirname(Rails.root.join('/path_to_folder/create.log'))
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      barcode = Barby::Code128B.new("appointment #{id}")
      blob = Barby::PngOutputter.new(barcode).to_png # Raw PNG data
      File.open(Rails.root.join(barcode_path), 'wb') { |f| f.write blob }
    end

    def barcode_path
      "/path_to_folder/#{id}.png"
    end
  end
end
