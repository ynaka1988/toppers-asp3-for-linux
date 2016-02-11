#!ruby -Ku
#
#  TOPPERS Configurator by Ruby
#
#  Copyright (C) 2015 by Embedded and Real-Time Systems Laboratory
#              Graduate School of Information Science, Nagoya Univ., JAPAN
#  Copyright (C) 2015 by FUJI SOFT INCORPORATED, JAPAN
#  Copyright (C) 2016 by APTJ Co., Ltd., JAPAN
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
#  $Id: GenFile.rb 25 2016-01-29 16:48:00Z ertl-hiro $
#

if ($0 == __FILE__)
  TOOL_ROOT = File.expand_path(File.dirname(__FILE__) + "/")
  $LOAD_PATH.unshift(TOOL_ROOT)
end

######################################################################
# 定数定義
######################################################################
NL  = "\n"
TAB = "\t"

######################################################################
# ファイル作成クラス定義
######################################################################
class GenFile
  @@hFileData = {}

  def initialize(sName)
    @sCurName = sName
    if (!@@hFileData.has_key?(sName))
      @@hFileData[@sCurName] = ""
    end
  end

  # ファイルデータに1行追加する
  def add(sCode = "")
    @@hFileData[@sCurName].concat(sCode + NL)
  end

  # ファイルデータに1行追加する(改行2回)
  def add2(sCode = "")
    add(sCode + NL)
  end

  # ファイルデータの末尾に文字列を追加する
  def append(sCode = "")
    @@hFileData[@sCurName].concat(sCode)
  end

  # ファイルデータの末尾が指定した文字の場合，その文字を除去する(改行やスペースを考慮)
  def chop_char(sChar, sCode = "")
    # 末尾の改行，スペースを取り出す
    sChopped = ""
    while (["\r", "\n", " "].include?(@@hFileData[@sCurName][-1]))
      sChopped = @@hFileData[@sCurName][-1] + sChopped
      @@hFileData[@sCurName].chop!()
    end

    # 改行コードを取り出した後の末尾がsCharの場合除去
    if (@@hFileData[@sCurName][-1] == sChar)
      @@hFileData[@sCurName].chop!()
    end

    # 取り出したコードを戻して，文字列を追加
    append(sChopped + sCode)
  end

  # 指定した文字の後にスペースがある場合，スペースも除去する
  def chop_char_sp(sChar, sCode = "")
    chop_char(sChar, sCode)
    while (@@hFileData[@sCurName][-1] == " ")
      @@hFileData[@sCurName].chop!()
    end
  end

  # ファイルデータの末尾が","の場合，","を除去する
  def chop_comma(sCode = "")
    chop_char(",", sCode)
  end

  # カンマの後にスペースがある場合，スペースも除去する
  def chop_comma_sp(sCode = "")
    chop_char_sp(",", sCode)
  end

  # コメントヘッダを追加する
  def comment_header(sComment)
    # 複数行対応
    aString = sComment.split(NL)

    add("/*")
    aString.each{|sLine|
      add(" *  " + sLine)
    }
    add2(" */")
  end

  # ファイルデータを表示する
  def print()
    puts(@@hFileData[@sCurName])
  end

  # 全ファイルを出力する
  def self.output()
    # エラー発生時は出力しない
    if ($error_flg == true)
      return
    end

    @@hFileData.each{|sName, sData|
      # 既にファイルが存在し，差分がない場合は出力しない(タイムスタンプを更新しない)
      if (File.exist?(sName))
        sCurrentData = File.read(sName)
        if (sData == sCurrentData)
          next
        end
      end
      File.open(sName, "w") {|io|
        puts("[#{File.basename($0)}] Generated #{sName}")
        io.puts(sData)
      }
    }
  end
end

