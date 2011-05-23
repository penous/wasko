require "color/palette/monocontrast"
require "yaml"

module Wasko
  class << self

    # ## Palette
    #
    # Trying to create a sensible palette that doesn't suck
    def palette_from_color(hex_color)
      palette = ::Color::Palette::MonoContrast.new(::Color::RGB.from_html(hex_color))

      palette_colors = {
        :background => color_to_rgb(palette.background[2]),
        :foreground => color_to_rgb(palette.foreground[2])
      }
      draw_rgb_color palette_colors
    end


    # ## Named Colors
    #
    # Applescript has a notion of named colors, these can be
    # used, but in the future I'm looking more to create
    # your own schemes.
    def colors
      %w(blue yellow white red orange green black brown cyan purple magenta)
    end

    def draw_named_color(color_name)
      run_applescript(script_with_color(color_name))
    end
    # Set background color to one of the named colors
    # available in `AppleScript`.
    def script_with_color(color)
      <<SCRIPT
tell application "Terminal"
  set background color of current settings of selected tab of first window to "#{color}"
end tell
SCRIPT
    end

    # ## RGB Colors
    #
    # Applescript uses `short int` to make the RGB like this:
    #
    #      {65535, 65535, 65535, 65535}
    #      { red, green, blue, opacity}
    #
    # The `color`-gem doesn't do this, so transforming the
    # values to something `Applescript` wouldn't mind'
    def color_to_rgb(color, opacity=100)
      rgb = [color.red.to_i * 257, color.green.to_i * 257, color.blue.to_i * 257, opacity * 65535/100].join(", ")
      "{#{rgb}}"
    end

    # Examples
    #
    #      Wasko.draw_css_color "ffffff"
    #       => Sets background color to white
    #
    #      Wasko.draw_css_color :background => "fff", :foreground => "ccc"
    #       => Sets back-and foreground color
    def draw_css_color(color_hash)
      unless Hash === color_hash
        color_hash = {:background => color_hash}
      end
      rgb_hash = color_hash.inject({}) do |h, (k, v)|
        h[k] = color_to_rgb(Color::RGB.from_html(v)) rescue "ffffff"
        h
      end
      draw_rgb_color rgb_hash
    end

    # Examples
    #
    #     Wasko.draw_rgb_color(:background => {65535, 65535,65535, 655535})
    #     Wasko.draw_rgb_color(:foreground => {65535, 65535,65535, 655535})
    def draw_rgb_color(color_hash)
      if color_hash[:background]
        run_applescript(script_with_rgb_for_background(color_hash[:background]))
      end

      if color_hash[:foreground]
        run_applescript(script_with_rgb_for_normal_text(color_hash[:foreground]))
      end
    end

    def script_with_rgb_for_normal_text(rgb_values)
      <<SCRIPT
tell application "Terminal"
  set normal text color of current settings of selected tab of first window to #{rgb_values}
end tell
SCRIPT
    end

    def script_with_rgb_for_background(rgb_values)
      <<SCRIPT
tell application "Terminal"
  set background color of current settings of selected tab of first window to #{rgb_values}
end tell
SCRIPT
    end

    def current_background_color
      script = <<SCRIPT
tell application "Terminal"
  get background color of current settings of selected tab of first window
end tell
SCRIPT
      run_applescript(script).gsub("\n", '')
    end

    def current_normal_text_color
      script = <<SCRIPT
tell application "Terminal"
  get normal text color of current settings of selected tab of first window
end tell
SCRIPT
      run_applescript(script).gsub("\n", '')
    end

    # Run the applescript from the command line.
    def run_applescript(script)
      `/usr/bin/osascript -e "#{script.gsub('"', '\"')}"`
    end

    # # Configuration

    def config_file_exists?
      File.exists?(File.join(ENV['HOME'],'.wasko'))
    end

    def config
      YAML::load(File.open(config_file))["wasko"]
    end

    def config_file
      File.join(ENV['HOME'],'.wasko')
    end

    def save_color_to_config(rgb_values, name)
      c = config ||= {}
      c[name] = rgb_values
      File.open(config_file, 'w') do |out|
        out.write({"wasko" => c}.to_yaml)
      end
    end
  end
end
