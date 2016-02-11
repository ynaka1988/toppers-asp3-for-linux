# -*- coding: utf-8 -*-
#
#  TOPPERS Configurator by Ruby
#
#  Copyright (C) 2015 by FUJI SOFT INCORPORATED, JAPAN
#  Copyright (C) 2015,2016 by Embedded and Real-Time Systems Laboratory
#              Graduate School of Information Science, Nagoya Univ., JAPAN
#
#  上記著作権者は，以下の(1)〜(4)の条件を満たす場合に限り，本ソフトウェ
#  ア（本ソフトウェアを改変したものを含む．以下同じ）を使用・複製・改
#  変・再配布（以下，利用と呼ぶ）することを無償で許諾する．
#  (1) 本ソフトウェアをソースコードの形で利用する場合には，上記の著作
#      権表示，この利用条件および下記の無保証規定が，そのままの形でソー
#      スコード中に含まれていること．
#  (2) 本ソフトウェアを，ライブラリ形式など，他のソフトウェア開発に使
#      用できる形で再配布する場合には，再配布に伴うドキュメント（利用
#      者マニュアルなど）に，上記の著作権表示，この利用条件および下記
#      の無保証規定を掲載すること．
#  (3) 本ソフトウェアを，機器に組み込むなど，他のソフトウェア開発に使
#      用できない形で再配布する場合には，次のいずれかの条件を満たすこ
#      と．
#    (a) 再配布に伴うドキュメント（利用者マニュアルなど）に，上記の著
#        作権表示，この利用条件および下記の無保証規定を掲載すること．
#    (b) 再配布の形態を，別に定める方法によって，TOPPERSプロジェクトに
#        報告すること．
#  (4) 本ソフトウェアの利用により直接的または間接的に生じるいかなる損
#      害からも，上記著作権者およびTOPPERSプロジェクトを免責すること．
#      また，本ソフトウェアのユーザまたはエンドユーザからのいかなる理
#      由に基づく請求からも，上記著作権者およびTOPPERSプロジェクトを
#      免責すること．
#
#  本ソフトウェアは，無保証で提供されているものである．上記著作権者お
#  よびTOPPERSプロジェクトは，本ソフトウェアに関して，特定の使用目的
#  に対する適合性も含めて，いかなる保証も行わない．また，本ソフトウェ
#  アの利用により直接的または間接的に生じたいかなる損害に関しても，そ
#  の責任を負わない．
#
#  $Id: pass2.rb 38 2016-02-06 02:45:11Z ertl-hiro $
#

#
#		パス2の処理
#

#
#  パス1の生成物の読み込み
#
def ReadCfg1Out
  # cfg1_out.symsの読み込み
  symbolAddress = ReadSymbolFile(CFG1_OUT_SYMS)

  # cfg1_out.srecの読み込み
  begin
    cfg1SRec = SRecord.new(CFG1_OUT_SREC)
  rescue Errno::ENOENT, Errno::EACCES => ex
    abort(ex.message)
  end

  # マジックナンバーの取得
  if symbolAddress.has_key?(CFG1_MAGIC_NUM)
    $asmLabel = ""
    cfg1_prefix = CFG1_PREFIX
  elsif symbolAddress.has_key?("_" + CFG1_MAGIC_NUM)
    $asmLabel = "_"
    cfg1_prefix = "_" + CFG1_PREFIX
  else
    error_exit("`#{CFG1_MAGIC_NUM}' is not found in `#{CFG1_OUT_SYMS}'")
  end

  magicNumberData = cfg1SRec.get_data(symbolAddress \
							[$asmLabel + CFG1_MAGIC_NUM], 4)
  if (magicNumberData == "12345678")
    $bLittleEndian = false
  elsif (magicNumberData == "78563412")
    $bLittleEndian = true
  else
    error_exit("`#{CFG1_MAGIC_NUM}' is invalid in `#{CFG1_OUT_SREC}'")
  end

  # 固定出力した変数の取得
  $sizeOfSigned = cfg1SRec.get_value(symbolAddress \
							[$asmLabel + CFG1_SIZEOF_SIGNED], 4, false)

  # 値取得シンボルの取得
  $symbolValueTable.each do |symbolName, symbolData|
    symbol = cfg1_prefix + symbolName
    if symbolAddress.has_key?(symbol)
      value = cfg1SRec.get_value(symbolAddress[symbol], \
							$sizeOfSigned, symbolData.has_key?(:SIGNED))
      if !value.nil?
        symbolData[:VALUE] = value
      end
    end
  end

  #
  #  ID番号入力ファイルの取り込み
  #
  $inputObjid = {}
  if !$idInputFileName.nil?
    begin
      idInputFile = File.open($idInputFileName)
    rescue Errno::ENOENT, Errno::EACCES => ex
      abort(ex.message)
    end

    idInputFile.each do |line|
      ( objidName, objidNumber ) = line.split(/\s+/)
      $inputObjid[objidName] = objidNumber.to_i
    end

    idInputFile.close
  end

  #
  #  ハッシュの初期化
  #
  $cfgData = {}
  objidValue = {}
  $apiDefinition.each do |apiName, apiDef|
    if apiDef.has_key?(:API)
      $cfgData[apiDef[:API].to_sym] = {}
    end
    apiDef[:PARAM].each do |apiParam|
      if apiParam.has_key?(:NAME) && apiParam.has_key?(:ID_DEF)
        objidValue[apiParam[:NAME]] = {}
      end
    end
  end

  #
  #  オブジェクトIDの割り当て
  #
  # ID番号割り当ての前処理
  $cfgFileInfo.each do |cfgInfo|
    # プリプロセッサディレクティブと消えた静的APIは読み飛ばす
    next if (cfgInfo.has_key?(:DIRECTIVE) || !symbolAddress.has_key?( \
							"#{cfg1_prefix}static_api_#{cfgInfo[:INDEX]}"))

    apiDef = $apiDefinition[cfgInfo[:API]]
    apiDef[:PARAM].each do |apiParam|
      if apiParam.has_key?(:NAME) && apiParam.has_key?(:ID_DEF)
        objidName = apiParam[:NAME]
        objidData = cfgInfo[objidName]
        if $inputObjid.has_key?(objidData)
          objidValue[objidName][objidData] = $inputObjid[objidData]
        else
          objidValue[objidName][objidData] = nil
        end
      end
    end
  end

  # ID番号の割り当て処理
  objidValue.each do |objidName, objidList|
    # 未使用のID番号のリスト（使用したものから消していく）
    unusedObjidList = (1.upto(objidList.keys.size)).to_a

    # 割り当て済みのID番号の処理
    objidList.each do |objidData, objidNumber|
      if $inputObjid.has_key?(objidData)
        objidIndex = unusedObjidList.index($inputObjid[objidData])
        if objidIndex.nil?
          # ID番号入力ファイルで指定された値が不正
          error_exit("value of `#{objidData}' in ID input file is illegal")
        else
          # 未使用のID番号のリストから削除
          unusedObjidList.delete_at(objidIndex)
        end
      end
    end

    # ID番号の割り当て
    objidList.each do |objidData, objidNumber|
      if objidList[objidData].nil?
        # 以下で，objidValueを書き換えている
        objidList[objidData] = unusedObjidList.shift
      end
    end
  end

  #
  #  静的APIデータをハッシュ形式へ変換
  #
  $cfgFileInfo.each do |cfgInfo|
    # プリプロセッサディレクティブは読み飛ばす
    next if cfgInfo.has_key?(:DIRECTIVE)

    apiDef = $apiDefinition[cfgInfo[:API]]
    apiSym = apiDef[:API].to_sym
    apiIndex = cfgInfo[:INDEX]

    # シンボルファイルに静的APIのインデックスが存在しなければ読み飛ばす
    #（ifdef等で消えた静的API）
    next unless symbolAddress.has_key?("#{cfg1_prefix}static_api_#{apiIndex}")

    # パラメータの値をハッシュ形式に格納
    params = {}
    apiDef[:PARAM].each do |apiParam|
      if apiParam.has_key?(:NAME)
        paramName = apiParam[:NAME]
        if cfgInfo.has_key?(paramName)
          paramData = cfgInfo[paramName]
          value = nil
          if apiParam.has_key?(:ID_DEF)			# オブジェクト識別名（定義）
            value = objidValue[paramName][paramData]
          elsif apiParam.has_key?(:ID_REF)		# オブジェクト識別名（参照）
            if objidValue[paramName].has_key?(paramData)
              value = objidValue[paramName][paramData]
            else
              error("E_OBJ: `#{paramData}' in #{cfgInfo[:API]} is not defined",
								"#{cfgInfo[:_FILE_]}:#{cfgInfo[:_LINE_]}:")
            end
          elsif apiParam.has_key?(:SIGNED) || apiParam.has_key?(:UNSIGNED)
            symbol = "#{cfg1_prefix}valueof_#{paramName}_#{apiIndex}"
            if (symbolAddress.has_key?(symbol))
              value = cfg1SRec.get_value(symbolAddress[symbol], \
							$sizeOfSigned, apiParam.has_key?(:SIGNED))
            end
          end
          params[paramName.to_sym] = StrVal.new(paramData, value)
        end
      end
    end

	# 登録キーを決定する
    if apiDef.has_key?(:KEYPAR)
      keyParam = params[apiDef[:KEYPAR].to_sym]
      key = keyParam.val
      if $cfgData[apiSym].has_key?(key)
		# 登録キーの重複
        error("E_OBJ: #{apiDef[:KEYPAR]} `#{keyParam}'" \
								" is duplicaed in #{cfgInfo[:API]}",
								"#{cfgInfo[:_FILE_]}:#{cfgInfo[:_LINE_]}:")
      end
    else
      key = $cfgData[apiSym].count + 1
    end

    # API名，ファイル名，行番号を追加
    params[:apiname] = cfgInfo[:API]
    params[:_file_] = cfgInfo[:_FILE_]
    params[:_line_] = cfgInfo[:_LINE_]
    $cfgData[apiSym][key] = params
  end

  #
  #  ID番号出力ファイルの生成
  #
  if !$idOutputFileName.nil?
    idOutputFile = GenFile.new($idOutputFileName)
    objidValue.each do |objidName, objidList|
      objidList.each do |objidData, objidNumber|
        idOutputFile.add("#{objidData} #{objidNumber}")
      end
    end
  end
end

#
#  パス2の処理
#
def Pass2
  #
  #  パス1から引き渡される情報をファイルから読み込む
  #
  db = PStore.new(CFG1_OUT_DB)
  db.transaction(true) do
    $apiDefinition = db[:apiDefinition]
    $symbolValueTable = db[:symbolValueTable]
    $cfgFileInfo = db[:cfgFileInfo]
    $includeFiles = db[:includeFiles]
  end

  #
  #  パス1の生成物を読み込む
  #
  ReadCfg1Out()
  abort if $errorFlag					# エラー発生時はabortする

  #
  #  値取得シンボルをグローバル変数として定義する
  #
  DefineSymbolValue()

  #
  #  生成スクリプト（trbファイル）を実行する
  #
  $trbFileNames.each do |trbFileName|
    IncludeTrb(trbFileName)
  end

  #
  #  パス3に引き渡す情報をファイルに生成
  #
  if $omitOutputDb.nil?
    db = PStore.new(CFG2_OUT_DB)
    db.transaction do
      db[:apiDefinition] = $apiDefinition
      db[:symbolValueTable] = $symbolValueTable
      db[:cfgFileInfo] = $cfgFileInfo
      db[:includeFiles] = $includeFiles
      db[:cfgData] = $cfgData
      db[:asmLabel] = $asmLabel
      db[:bLittleEndian] = $bLittleEndian
      db[:cfg2Data] = $cfg2Data
    end
  end
end
