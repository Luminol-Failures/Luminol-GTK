require_relative 'luminol/system/version'
require_relative 'luminol/ui/application'
require 'gtk3'

module Luminol
  def self.start
    begin
      resource = Gio::Resource.load(File.join(__dir__, 'luminol', 'gresources.bin'))
      Gio::Resources.register(resource)

      app = Application.new
      puts app.run
    rescue StandardError => e
      # raise e
      dialog = Gtk::MessageDialog.new(
        buttons: :ok_cancel,
        message_type: :error
      )

      dialog.text = "An error has occurred: <#{e.message}>",
      dialog.secondary_text = e.backtrace.join("\n")

      result = dialog.run
      dialog.destroy

      retry if result == :ok
    end
  end
end

