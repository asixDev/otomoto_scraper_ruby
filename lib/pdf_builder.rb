# frozen_string_literal: true

require "prawn"
require "csv"

module OtomotoPdfBuilder
  def self.build(io_csv)
    csv = CSV.parse(io_csv, headers: true)
    Prawn::Document.generate("output/cars.pdf") do |pdf|
      pdf.line_width 2
      pdf.font_families.update("Arial" => {
                                 normal: "assets/fonts/Arial-Unicode-Regular.ttf",
                                 italic: "assets/fonts/Arial-Unicode-Italic.ttf",
                                 bold: "assets/fonts/Arial-Unicode-Bold.ttf",
                                 bold_italic: "assets/fonts/Arial-Unicode-Bold-Italic.ttf"
                               })
      pdf.font "Arial"
      pdf.define_grid(columns: 7, rows: 20, gutter: 0.5)
      width = pdf.grid.column_width
      height = pdf.grid.row_height
      current_grid_height = 0
      csv.each do |row|
        if current_grid_height >= pdf.grid.rows
          pdf.start_new_page
          current_grid_height = 0
        end
        pdf.grid([current_grid_height, 0], [current_grid_height + 3, 6]).bounding_box { pdf.stroke_horizontal_rule }
        pdf.grid([current_grid_height, 3], [current_grid_height + 3, 6]).bounding_box { pdf.stroke_bounds }
        pdf.grid([current_grid_height, 0], [current_grid_height + 3, 2]).bounding_box do
          pdf.image "output/images/#{row["id"]}.png",
                    fit: [width * 3, height * 4],
                    position: :right,
                    vposition: :center
        end
        pdf.grid([current_grid_height, 3], [current_grid_height, 6]).bounding_box do
          pdf.text_box "<b>#{row["name"]} - <color rgb='FF0000'>#{row["price"]}</color></b>",
                       align: :center,
                       valign: :center,
                       inline_format: true,
                       overflow: :shrink_to_fit
          pdf.stroke_bounds
        end
        { "production" => "Rocznik - ", "mileage" => "Przebieg - ",
          "fuel" => "Paliwo - ", "horsepower" => "Moc - ", "color" => "Kolor - ", "wear" => "Stan - " }.each_with_index do |(key, value), index|
          pdf.grid([current_grid_height + 1 + index % 3, 3 + (index / 3 * 2)],
                   [current_grid_height + 1 + index % 3, 4 + (index / 3 * 2)]).bounding_box do
            pdf.indent(10) do
              pdf.text_box " #{value}#{row[key]}",
                           valign: :center
            end
          end
        end
        current_grid_height += 4
      end
    end
    io_csv.close
  end
end
