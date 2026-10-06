inherited BackendDelphiCadastro: TBackendDelphiCadastro
  Width = 402
  object qryPesquisa: TFDQuery
    Connection = Connection
    Left = 200
    Top = 40
  end
  object qryRecordCount: TFDQuery
    Connection = Connection
    Left = 304
    Top = 40
    object qryRecordCountCOUNT: TLargeintField
      FieldName = 'COUNT'
    end
  end
  object qryCadastro: TFDQuery
    Connection = Connection
    Left = 200
    Top = 112
  end
end
