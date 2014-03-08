require "rubygems"
require "rbconfig"
require "win32ole"
require "find"
require "fileutils"

$ruby_path = File::join(RbConfig::CONFIG["bindir"], RbConfig::CONFIG["ruby_install_name"]) + "w" + RbConfig::CONFIG["EXEEXT"]

File::expand_path(__FILE__) =~ /^(.+)\/plugin\/mikutter-windows/
$mikutter_dir = $1


def modify_immodules_cache!()
  Find::find(Gem.default_dir).select { |a| a =~ /\/immodules.cache$/ }.each { |file|
    dir = File::expand_path(File::dirname(file))

    imime_path = File::join(dir, "immodules", "im-ime.dll")

    if !File::exist?(imime_path)
      next
    end

    file_bak = file + ".bak"

    FileUtils.cp(file, file_bak)

    File.open(file_bak) { |fpr|
      File.open(file, "w") { |fpw|
        fpr.each { |line|
          if line =~ /\/im-ime.dll\"/
            fpw.puts("\"#{imime_path}\"") 
          else
            fpw.puts(line)
          end
        }
      }
    }
  }
end


def png2ico(png, ico)
  File.open(ico, "wb") { |ico_fp|
    ico_fp.write([0, 1, 1].pack("s3"))
    ico_fp.write([0, 0, 0, 0, 1, 3, File::size(png), 22].pack("c4s2l2"))

    File.open(png, "rb") { |png_fp|
      data = png_fp.read()
      ico_fp.write(data)
    }
  }
end


def create_shortcut!()
  png2ico(File::join($mikutter_dir, "core", "skin", "data", "icon.png"), File::join($mikutter_dir, "plugin", "mikutter-windows", "icon.ico"))

  wshell = WIN32OLE.new("WScript.Shell")
  shortcut = wshell.CreateShortcut(File.join(wshell.SpecialFolders("Desktop"), "mikutter.lnk"))

  shortcut.TargetPath = $ruby_path
  shortcut.Arguments = "#{$mikutter_dir}/mikutter.rb"
  shortcut.IconLocation = "#{$mikutter_dir}/plugin/mikutter-windows/icon.ico"
  shortcut.WorkingDirectory = $mikutter_dir
  shortcut.Save
end


def bundle!()
  system("gem install bundler")

  Dir.chdir($mikutter_dir)
  system("bundle install")
end


bundle!

modify_immodules_cache!

create_shortcut!