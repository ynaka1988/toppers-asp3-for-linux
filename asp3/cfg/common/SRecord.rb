#!ruby -Ku
#
#  TOPPERS Configurator by Ruby
#
#  Copyright (C) 2015 by Embedded and Real-Time Systems Laboratory
#              Graduate School of Information Science, Nagoya Univ., JAPAN
#  Copyright (C) 2015 by FUJI SOFT INCORPORATED, JAPAN
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
#  $Id: SRecord.rb 25 2016-01-29 16:48:00Z ertl-hiro $
#

######################################################################
# Sレコードファイル処理クラス定義
######################################################################
class SRecord
  def initialize(sFile)
    @hSrecData = {}
    @sOneLineData = ""
    File.open(sFile){|cFile|
      cFile.each{|sLine|
        # レコードタイプ
        sType = sLine.slice(0, 2)

        # データレコードのみ処理する
        case sType
        when "S1"
          # データ長(アドレス分[2byte]+チェックサム分1byteを減算)
          nLength = sLine.slice(2, 2).hex() - 2 - 1

          # アドレス(4文字=2byte)
          nAddress = sLine.slice(4, 4).hex()

          # データ(この時点では文字列で取っておく)
          sData = sLine.slice(8, nLength * 2)
        when "S2"
          # データ長(アドレス分[3byte]+チェックサム分1byteを減算)
          nLength = sLine.slice(2, 2).hex() - 3 - 1

          # アドレス(6文字=3byte)
          nAddress = sLine.slice(4, 6).hex()

          # データ(この時点では文字列で取っておく)
          sData = sLine.slice(10, nLength * 2)
        when "S3"
          # データ長(アドレス分[4byte]+チェックサム分1byteを減算)
          nLength = sLine.slice(2, 2).hex() - 4 - 1

          # アドレス(8文字=4byte)
          nAddress = sLine.slice(4, 8).hex()

          # データ(この時点では文字列で取っておく)
          sData = sLine.slice(12, nLength * 2)
        else
          nAddress = nil
        end

        if (!nAddress.nil?)
          @hSrecData[nAddress] = sData
        end
      }
    }
    @hSrecData.freeze()

    # 全データを1行に変換(先頭アドレスを取得しておく)
    @nHeadAddress = nil
    nPreAddress = nil
    nPreData = nil
    @hSrecData.each{|nAddress, sData|
      if (@nHeadAddress.nil?)
        @nHeadAddress = nAddress
      end

      # アドレスが飛んだ場合0で埋めておく
      if (!nPreAddress.nil? && !nPreData.nil?)
        nOffset = nAddress - nPreAddress
        nDiff = nOffset - (nPreData.size() / 2)
        if (nDiff > 0)
          @sOneLineData += "0" * (nDiff * 2)
        end
      end
      nPreAddress = nAddress
      nPreData = sData

      # 全データに追加
      @sOneLineData += sData
    }
  end

  # データ取得
  def get_data(nAddress, nSize)
    # アドレス範囲外の場合
    nChkSize = ((nAddress - @nHeadAddress) * 2) + (nSize * 2)
    if (nChkSize > @sOneLineData.size())
      return nil
    else
      return @sOneLineData.slice(((nAddress - @nHeadAddress) * 2), (nSize * 2))
    end
  end

  # データ書込み
  def set_data(nAddress, sData)
    nIdx = (nAddress - @nHeadAddress) * 2
    sData.chars{|sChar|
      @sOneLineData[nIdx] = sChar
      nIdx += 1
    }
  end

  # 値としてのデータ取得
  def get_value(nAddress, nSize, bSigned)
    nReturnData = nil
    sTargetData = get_data(nAddress, nSize)
    if (sTargetData.nil?)
      return nil
    end

    # リトルエンディアンの場合，バイトオーダーを逆にする
    if ($bLittleEndian == true)
      sReverseStr = ""
      # 後ろから2文字ずつ抜き出し，並び替える
      while (sTargetData.size() != 0)
        sReverseStr += sTargetData[-2]
        sReverseStr += sTargetData[-1]
        sTargetData.chop!().chop!()
      end
      sTargetData = sReverseStr
    end

    if (bSigned == false)
      # 符号無しの場合，そのまま16進数として解釈する
      nReturnData = sTargetData.hex()
    else
      # 1文字目を2進数の文字列で取得
      sBin = sprintf("%04b", sTargetData[0].hex())
      if (sBin[0] == "0")
        # 正の数であればそのまま変換
        nReturnData = sTargetData.hex()
      else
        # 2の補数表現から負の値を取得
        nBaseNum = ("0x1" + ("0" * nSize * 2)).hex()
        nReturnData = (-1) * (nBaseNum - sTargetData.hex())
      end
    end

    return nReturnData
  end
end
