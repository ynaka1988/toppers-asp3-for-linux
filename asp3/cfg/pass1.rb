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
#  $Id: pass1.rb 40 2016-02-06 17:15:00Z ertl-hiro $
#

#
#		パス1の処理
#

#
#  値取得シンボルテーブルへの固定登録
#
$symbolValueTable = {
  "CHAR_BIT" => { :EXPR => "CHAR_BIT" },
  "SCHAR_MAX" => { :EXPR => "SCHAR_MAX", :SIGNED => true },
  "SCHAR_MIN" => { :EXPR => "SCHAR_MIN", :SIGNED => true },
  "UCHAR_MAX" => { :EXPR => "UCHAR_MAX" },
  "CHAR_MAX" => { :EXPR => "CHAR_MAX", :SIGNED => true },
  "CHAR_MIN" => { :EXPR => "CHAR_MIN", :SIGNED => true },
  "SHRT_MAX" => { :EXPR => "SHRT_MAX", :SIGNED => true },
  "SHRT_MIN" => { :EXPR => "SHRT_MIN", :SIGNED => true },
  "USHRT_MAX" => { :EXPR => "USHRT_MAX" },
  "INT_MAX" => { :EXPR => "INT_MAX", :SIGNED => true },
  "INT_MIN" => { :EXPR => "INT_MIN", :SIGNED => true },
  "UINT_MAX" => { :EXPR => "UINT_MAX" },
  "LONG_MAX" => { :EXPR => "LONG_MAX", :SIGNED => true },
  "LONG_MIN" => { :EXPR => "LONG_MIN", :SIGNED => true },
  "ULONG_MAX" => { :EXPR => "ULONG_MAX" }
}

#
#  静的APIテーブルへの固定登録
#
$apiDefinition = { "INCLUDE" =>
  { :PARAM => [ { :NAME => :file, :STRING => true }]}}

#
#  静的APIテーブルの読み込み
#
def ReadApiTableFile
  $apiTableFileNames.each do |apiTableFileName|
    if !File.exist?(apiTableFileName)
      error_exit("`#{apiTableFileName}' not found")
      next
    end

    apiFile = File.open(apiTableFileName)
    apiFile.each do |line|
      next if /^#/ =~ line			# コメントをスキップ

      fields = line.split(/\s+/)
      staticApi = fields.shift
      apiDef = { :API => staticApi }
      apiParams = []
      fields.each do |param|
        case param
        when /^(\W*)(\w+)(\W*)$/
          prefix = $1
          name = $2
          postfix = $3
          apiParam = { :NAME => name }

          case prefix
          when "#"					# オブジェクト識別名（定義）
            apiParam[:ID_DEF] = true
          when "%"					# オブジェクト識別名（参照）
            apiParam[:ID_REF] = true
          when "."					# 符号無し整数定数式パラメータ
            apiParam[:UNSIGNED] = true
          when "+"					# 符号付き整数定数式パラメータ
            apiParam[:SIGNED] = true
          when "&"					# 一般整数定数式パラメータ
            # do nothing
          when "$"					# 文字列定数式パラメータ
            apiParam[:STRING] = true
          else
            error_exit("`#{param}' is invalid")
          end

          case postfix
          when "*"					# キーを決めるパラメータ
            apiDef[:KEYPAR] = name
          when "?"					# オプションパラメータ
            apiParam[:OPTIONAL] = true
          when "\.\.\."				# リストパラメータ
            apiParam[:LIST] = true
          end
        
        when /^([{}])$/				# {と}
          apiParam = { :BRACE => $1 }

        else
          error_exit("`#{param}' is invalid")
        end
        apiParams.push(apiParam)
      end
      apiDef[:PARAM] = apiParams
      $apiDefinition[staticApi] = apiDef
    end
    apiFile.close
  end
end

#
#  値取得シンボルテーブルの読み込み
#
def ReadSymvalTable
  $symvalTableFileNames.each do |symvalTableFileName|
    if !File.exist?(symvalTableFileName)
      error_exit("`#{symvalTableFileName}' not found")
      next
    end

    symvalCsv = CSV.open(symvalTableFileName)
    symvalCsv.each do |record|
      # 変数名
      if record[0].nil?
        error_exit("invalid variable name in `#{fileName}'")
      end

      symbol = {}
      variable = record[0]

      # 式
      if record[1].nil? || record[1] == ""
        symbol[:EXPR] = variable
      else
        symbol[:EXPR] = record[1]
      end

      # 符号フラグ
      if !(record[2].nil? || record[2] == "" || /^[uU]/ =~ record[2])
        symbol[:SIGNED] = true
      end

      # コンパイル条件
      symbol[:CONDITION] = record[3]

      # コンパイル条件が満たされない時のデフォルト値
      symbol[:DEFAULT] = record[4]

      $symbolValueTable[variable] = symbol
    end
    symvalCsv.close
  end
end

#
#  システムコンフィギュレーションファイルからの読み込みクラス
#
class ConfigFile
  def initialize(fileName)
    @cfgFileName = fileName
    begin
      @cfgFile = File.open(@cfgFileName)
    rescue Errno::ENOENT, Errno::EACCES => ex
      abort(ex.message)
    end
    @lineNo = 0
    @withinComment = false
  end

  def close
    @cfgFile.close
  end

  def getNextLine(withinApi)
    line = @cfgFile.gets
    return(nil) if line.nil?
    @lineNo += 1

    line.chomp!
    if @withinComment
      case line
      when /\*\//						# C言語スタイルのコメント終了
        line.sub!(/^.*?\*\//, "")		# 最初の*/にマッチさせる */
        @withinComment = false
      else
        line = ""
      end
    end
    if !@withinComment
      line.gsub!(/\/\*.*?\*\//, "")		# C言語スタイルのコメントの除去
										# 最初の*/にマッチさせる */
      case line
      when /^\s*#/						# プリプロセッサディレクティブ
        if withinApi
          parse_error(self, \
					"preprocessor directive must not be within static API")
          line = ""
        end
      when /\/\*/						# C言語スタイルのコメント開始
        line.sub!(/\/\*.*$/, "")
        @withinComment = true
      when /\/\//						# C++言語スタイルのコメント
        line.sub!(/\/\/.*$/, "")
      end
    end
    return(line)
  end

  def getFileName
    return(@cfgFileName)
  end

  def getLineNo
    return(@lineNo)
  end
end

#
#  システムコンフィギュレーションファイルのパーサークラス
#
class CfgParser
  @@lastApiIndex = 0

  def initialize
    @line = ""
    @skipComma = false						# 次が,であれば読み飛ばす
  end

  #
  #  文字列末まで読む
  #
  def parseString(cfgFile)
    string = ""
    begin
      case @line
      when /^([^"]*\\\\)(.*)$/				# \\まで読む
        string += $1
        @line = $2
      when /^([^"]*\\\")(.*)$/				# \"まで読む
        string += $1
        @line = $2
      when /^([^"]*\")(.*)$/				# "まで読む
        string += $1
        @line = $2
        return(string)
      else									# 行末まで読む
        string += @line + "\n"
        @line = cfgFile.getNextLine(true)
      end
    end while (@line)
    error_exit("unterminated string meets end-of-file")
    return(string)
  end

  #
  #  文字末まで読む
  #
  def parseChar(cfgFile)
    string = ""
    begin
      case @line
      when /^([^']*\\\\)(.*)$/				# \\まで読む
        string += $1
        @line = $2
      when /^([^']*\\\')(.*)$/				# \'まで読む
        string += $1
        @line = $2
      when /^([^']*\')(.*)$/				# 'まで読む
        string += $1
        @line = $2
        return(string)
      else									# 行末まで読む
        string += @line + "\n"
        @line = cfgFile.getNextLine(true)
      end
    end while (@line)
    error_exit("unterminated string meets end-of-file")
    return(string)
  end

  #
  #  改行と空白文字を読み飛ばす
  #
  def skipSpace(cfgFile, withinApi)
    begin
      return if @line.nil?						# ファイル末であればリターン
      @line.lstrip!								# 先頭の空白を削除
      return if @line != ""						# 空行でなければリターン
      @line = cfgFile.getNextLine(withinApi)	# 次の行を読む
    end while true
  end

  #
  #  パラメータを1つ読む
  #
  # @lineの先頭からパラメータを1つ読んで，それを文字列で返す．読んだパ
  # ラメータは，@lineからは削除する．パラメータの途中で行末に達した時は，
  # cfgFileから次の行を取り出す．ファイル末に達した時は，nilを返す．
  #
  def parseParam(cfgFile)
    skipSpace(cfgFile, true)				# 改行と空白文字を読み飛ばす
    if @line.nil?							# ファイル末であればリターン
      error_exit("unexpexced end-of-file")
      return(nil)
    end

    param = ""								# 読んだ文字列
    parenLevel = 0							# 括弧のネストレベル
    skipComma = @skipComma
    @skipComma = false

    begin
      if parenLevel == 0
        case @line
        when /^(\s*,)(.*)$/					# ,
          @line = $2
          if param == "" && skipComma
            skipComma = false
            return(parseParam(cfgFile))		# 再帰呼び出し
          else
            return(param)
          end
        when /^(\s*{)(.*)$/					# {
          if param != ""
            return(param)
          else
            @line = $2
            return("{")
          end
        when /^(\s*\()(.*)$/				# (
          param += $1
          @line = $2
          parenLevel += 1
        when /^(\s*([)}]))(.*)$/			# }か)
          if param != ""
            return(param)
          else
            @line = $3
            @skipComma = true if $2 == "}"
            return($2)
          end
        when /^(\s*\")(.*)$/				# "
          @line = $2
          param += $1 + parseString(cfgFile)
        when /^(\s*\')(.*)$/				# '
          @line = $2
          param += $1 + parseChar(cfgFile)
        when /^(\s*[^,{}()"'\s]+)(.*)$/		# その他の文字列
          param += $1
          @line = $2
        else								# 行末
          param += "\n"
          @line = cfgFile.getNextLine(true)
        end
      else
        # 括弧内の処理
        case @line
        when /^(\s*\()(.*)$/				# "("
          param += $1
          @line = $2
          parenLevel += 1
        when /^(\s*\))(.*)$/				# ")"
          param += $1
          @line = $2
          parenLevel -= 1
        when /^(\s*\")(.*)$/				# "
          @line = $2
          param += $1 + parseString(cfgFile)
        when /^(\s*\')(.*)$/				# '
          @line = $2
          param += $1 + parseChar(cfgFile)
        when /^(\s*[^()"'\s]+)(.*)$/		# その他の文字列
          param += $1
          @line = $2
        else								# 行末
          param += "\n"
          @line = cfgFile.getNextLine(true)
        end
      end
    end while (@line)
    return(param)
  end

  def getParam(apiParam, param, cfgFile)
    if apiParam.has_key?(:ID_DEF) || apiParam.has_key?(:ID_REF)
      if /^[A-Za-z_][A-Za-z0-9_]*$/ !~ param
        parse_error(cfgFile, "`#{param}' is illegal object identifier")
      end
    end
    if apiParam.has_key?(:STRING)
      return(param.unquote)
    else
      return(param)
    end
  end

  def parseApi(cfgFile, apiName)
    # 静的APIの読み込み
    staticApi = {}
    tooFewParams = false

    skipSpace(cfgFile, true)				# 改行と空白文字を読み飛ばす
    if @line.nil?							# ファイル末であればリターン
      error_exit("unexpexced end-of-file")
    elsif (/^\((.*)$/ =~ @line)
      @line = $1

      staticApi[:API] = apiName
      staticApi[:_FILE_] = cfgFile.getFileName
      staticApi[:_LINE_] = cfgFile.getLineNo
      apiDef = $apiDefinition[apiName]
      param = parseParam(cfgFile)

      apiDef[:PARAM].each do |apiParam|
        return(staticApi) if param.nil?		# ファイル末であればリターン

        if apiParam.has_key?(:OPTIONAL)
          if /^([{})])$/ !~ param
            staticApi[apiParam[:NAME]] = getParam(apiParam, param, cfgFile)
            param = parseParam(cfgFile)
          end
        elsif apiParam.has_key?(:LIST)
          staticApi[apiParam[:NAME]] = []
          while /^([{})])$/ !~ param
            staticApi[apiParam[:NAME]].push(getParam(apiParam, param, cfgFile))
            param = parseParam(cfgFile)
            break if param.nil?				# ファイル末の場合
          end
        elsif !apiParam.has_key?(:BRACE)
          if /^([{})])$/ !~ param
            staticApi[apiParam[:NAME]] = getParam(apiParam, param, cfgFile)
            param = parseParam(cfgFile)
          elsif !tooFewParams
            parse_error(cfgFile, "too few parameters before `#{$1}'")
            tooFewParams = true
          end
        elsif param == apiParam[:BRACE]
          param = parseParam(cfgFile)
          tooFewParams = false
        else
          parse_error(cfgFile, "`#{apiParam[:BRACE]}' expected")
          # )かファイル末まで読み飛ばす
          begin
            param = parseParam(cfgFile)
            break if (param.nil? || param == ")")
          end while true
          break
        end
      end

      # 期待されるパラメータをすべて読んだ後の処理
      if param != ")"
        begin
          param = parseParam(cfgFile)
          return(staticApi) if param.nil?	# ファイル末であればリターン
        end while param != ")"
        parse_error(cfgFile, "too many parameters before `)'")
      end
    else
      parse_error(cfgFile, "syntax error: #{@line}")
      @line = ""
    end
    return(staticApi)
  end

  def parseFile(cfgFileName)
    cfgFiles = [ ConfigFile.new(cfgFileName) ]
    @line = ""
    begin
      cfgFile = cfgFiles.last
      skipSpace(cfgFile, false)				# 改行と空白文字を読み飛ばす
      if @line.nil?
        # ファイル末の処理
        cfgFiles.pop.close
        if cfgFiles.empty?
          break								# パース処理終了
        else
          @line = ""						# 元のファイルに戻って続ける
        end
      elsif /^;(.*)$/ =~ @line
        # ;は読み飛ばす
        @line = $1
      elsif /^#/ =~ @line
        # プリプロセッサディレクティブを読む
        case @line
        when /^#include\b(.*)$/
          $includeFiles.push($1.strip)
        when /^#(ifdef|ifndef|if|endif|else|elif)\b/
          directive = { :DIRECTIVE => @line.strip }
          $cfgFileInfo.push(directive)
        else
          parse_error(cfgFile, "unknown preprocessor directive: #{@line}")
        end
        @line = ""
      elsif (/^([A-Z_]+)\b(.*)$/ =~ @line)
        apiName = $1
        @line = $2

        case apiName
        when "KERNEL_DOMAIN"
          parse_error(cfgFile, "`KERNEL_DOMAIN' is not supported")
          abort()
        when "DOMAIN"
          parse_error(cfgFile, "`DOMAIN' is not supported")
          abort()
        when "CLASS"
          parse_error(cfgFile, "`CLASS' is not supported")
          abort()
        else
          if $apiDefinition.has_key?(apiName)
            # 静的APIを1つ読む
            staticApi = parseApi(cfgFile, apiName)
            if staticApi.empty?
              # ファイル末か文法エラー
            elsif (staticApi[:API] == "INCLUDE")
              # INCLUDEの処理
              includeFilePath = SearchFilePath(staticApi[:file])
              if includeFilePath.nil?
                parse_error(cfgFile, "`#{staticApi["file"]}' not found")
              else
                $dependencyFiles.push(includeFilePath)
                cfgFiles.push(ConfigFile.new(includeFilePath))
              end
            else
              # 静的APIの処理
              staticApi[:INDEX] = (@@lastApiIndex += 1)
              $cfgFileInfo.push(staticApi)
            end
          else
            parse_error(cfgFile, "unknown static API: #{apiName}")
          end
        end
      elsif (/^\}(.*)$/ =~ @line)
        # }の処理
        error_exit("unexpexced `}'")
        @line = $1
      else
        parse_error(cfgFile, "syntax error: #{@line}")
        @line = ""
      end
    end while true
  end
end

#
#  cfg1_out.cの生成
#
def GenerateCfg1OutC
  cfg1Out = GenFile.new(CFG1_OUT_C)

  cfg1Out.append(<<EOS)
/* #{CFG1_OUT_C} */
#define TOPPERS_CFG1_OUT
#include "kernel/kernel_int.h"
EOS

  # インクルードヘッダファイル
  $includeFiles.each do |file|
    cfg1Out.add("#include #{file}")
  end

  cfg1Out.append(<<EOS)

#ifdef INT64_MAX
  typedef int64_t signed_t;
  typedef uint64_t unsigned_t;
#else
  typedef int32_t signed_t;
  typedef uint32_t unsigned_t;
#endif

#include "#{CFG1_OUT_TARGET_H}"
#include <limits.h>

const uint32_t #{CFG1_MAGIC_NUM} = 0x12345678;
const uint32_t #{CFG1_SIZEOF_SIGNED} = sizeof(signed_t);

EOS

  # 値取得シンボルの処理
  $symbolValueTable.each do |symbolName, symbolData|
    type = symbolData.has_key?(:SIGNED) ? "signed_t" : "unsigned_t"
    if !symbolData[:CONDITION].nil?
      cfg1Out.add("#if #{symbolData[:CONDITION]}")
    end
    cfg1Out.add("const #{type} #{CFG1_PREFIX}#{symbolName} = " \
							"(#{type})(#{symbolData[:EXPR]});")
    if !symbolData[:DEFAULT].nil?
      cfg1Out.add("#else")
      cfg1Out.add("const #{type} #{CFG1_PREFIX}#{symbolName} = " \
							"(#{type})(#{symbolData[:DEFAULT]});")
    end
    if !symbolData[:CONDITION].nil?
      cfg1Out.add("#endif")
    end
  end

  # 静的API／プリプロセッサディレクティブの処理
  $cfgFileInfo.each do |cfgInfo|
    if cfgInfo.has_key?(:DIRECTIVE)
      cfg1Out.add2(cfgInfo[:DIRECTIVE])
    else
      apiDef = $apiDefinition[cfgInfo[:API]]
      apiIndex = cfgInfo[:INDEX]
      cfg1Out.add("#line #{cfgInfo[:_LINE_]} \"#{cfgInfo[:_FILE_]}\"")
      cfg1Out.add("const unsigned_t #{CFG1_PREFIX}static_api_" \
										"#{apiIndex} = #{apiIndex};")
      apiDef[:PARAM].each do |apiParam|
        if apiParam.has_key?(:ID_DEF)
          cfg1Out.add("#define #{cfgInfo[apiParam[:NAME]]}\t(<>)")
        elsif (apiParam.has_key?(:SIGNED) || apiParam.has_key?(:UNSIGNED)) \
										&& !cfgInfo[apiParam[:NAME]].nil?
          type = apiParam.has_key?(:SIGNED) ? "signed_t" : "unsigned_t"
          cfg1Out.add("#line #{cfgInfo[:_LINE_]} \"#{cfgInfo[:_FILE_]}\"")
          cfg1Out.add("const #{type} #{CFG1_PREFIX}valueof_" \
							"#{apiParam[:NAME]}_#{apiIndex} = " \
							"(#{type})(#{cfgInfo[apiParam[:NAME]]});")
        end
      end
      cfg1Out.add
    end
  end
end

#
#  パス1の処理
#
def Pass1
  # 
  #  タイムスタンプファイルの指定
  # 
  $timeStampFileName = CFG1_OUT_TIMESTAMP

  #
  #  静的APIテーブルの読み込み
  #
  ReadApiTableFile()

  #
  #  値取得シンボルテーブルの読み込み
  #
  ReadSymvalTable()

  #
  #  システムコンフィギュレーションファイルの読み込み
  #
  $cfgFileInfo = []
  $dependencyFiles = $configFileNames.dup
  $includeFiles = []
  $configFileNames.each do |configFileName|
    CfgParser.new.parseFile(configFileName)
  end
  abort if $errorFlag					# エラー発生時はabortする

  #
  #  cfg1_out.cの生成
  #
  GenerateCfg1OutC()

  #
  #  依存関係の出力
  #
  if !$dependencyFileName.nil?
    if $dependencyFileName == ""
      depFile = STDOUT
    else
      begin
        depFile = File.open($dependencyFileName, "w")
      rescue Errno::ENOENT, Errno::EACCES => ex
        abort(ex.message)
      end
    end

    depFile.print("#{CFG1_OUT_C} #{CFG1_OUT_DB}:")
    $dependencyFiles.each do |fileName|
      depFile.print(" #{fileName}")
    end
    depFile.puts("")

    if $dependencyFileName != ""
      depFile.close
    end
  end

  #
  #  パス2に引き渡す情報をファイルに生成
  #
  if $omitOutputDb.nil?
    db = PStore.new(CFG1_OUT_DB)
    db.transaction do
      db[:apiDefinition] = $apiDefinition
      db[:symbolValueTable] = $symbolValueTable
      db[:cfgFileInfo] = $cfgFileInfo
      db[:includeFiles] = $includeFiles
    end
  end
end
