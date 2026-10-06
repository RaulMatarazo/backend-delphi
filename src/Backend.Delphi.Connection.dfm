object BackendDelphiConnection: TBackendDelphiConnection
  OldCreateOrder = True
  Height = 265
  Width = 173
  object Connection: TFDConnection
    Params.Strings = (
      'ConnectionDef=ERPPGM_Pooled')
    ConnectedStoredUsage = []
    LoginPrompt = False
    Left = 64
    Top = 32
  end
  object FDPhysPgDriverLink: TFDPhysPgDriverLink
    VendorLib = 
      'C:\Users\RUM\OneDrive\Documentos\psqlodbc_09_05_0100\psqlodbc\li' +
      'bpq.dll'
    Left = 64
    Top = 104
  end
  object FDGUIxWaitCursor: TFDGUIxWaitCursor
    Provider = 'Console'
    Left = 64
    Top = 184
  end
end
