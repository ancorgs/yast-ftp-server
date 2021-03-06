# encoding: utf-8

# File:	include/ftp-server/wizards.ycp
# Package:	Configuration of ftp-server
# Summary:	Wizards definitions
# Authors:	Jozef Uhliarik <juhliarik@suse.cz>
#
# $Id: wizards.ycp 27914 2006-02-13 14:32:08Z juhliarik $
module Yast
  module FtpServerWizardsInclude
    def initialize_ftp_server_wizards(include_target)
      Yast.import "UI"

      textdomain "ftp-server"

      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "ftp-server/complex.rb"
      Yast.include include_target, "ftp-server/dialogs.rb"
    end

    def RunDaemonSwitch
      if FtpServer.vsftpd_edit
        return :vsftpd
      else
        return :pureftpd
      end
    end

    # Main workflow of the ftp-server configuration
    # @return sequence result
    def MainSequence
      aliases = {
        "init"     => [lambda { RunDaemonSwitch() }, false],
        "vsftpd"   => lambda { RunFTPDialogsVsftpd() },
        "pureftpd" => lambda { RunFTPDialogsPureftpd() }
      }

      sequence = {
        "ws_start" => "init",
        "init"     => { :pureftpd => "pureftpd", :vsftpd => "vsftpd" },
        "pureftpd" => { :abort => :abort, :next => :next, :vsftpd => "vsftpd" },
        "vsftpd"   => {
          :abort    => :abort,
          :next     => :next,
          :pureftpd => "pureftpd"
        }
      }
      temp = Empty()
      Wizard.SetContents("", temp, "", false, false)
      ret = Sequencer.Run(aliases, sequence)
      deep_copy(ret)
    end


    # Whole configuration of ftp-server
    # @return sequence result
    def FtpdSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("ftp-server")
      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of ftp-server but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def FtpServerAutoSequence
      aliases = { "main" => lambda { MainSequence() } }

      sequence = {
        "ws_start" => "main",
        "main"     => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("ftp-server")

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
