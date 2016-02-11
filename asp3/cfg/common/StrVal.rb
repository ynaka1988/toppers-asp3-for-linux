#!ruby -Ku
#
#  TOPPERS Configurator by Ruby
#
#  Copyright (C) 2015,2016 by Embedded and Real-Time Systems Laboratory
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
#  $Id: StrVal.rb 25 2016-01-29 16:48:00Z ertl-hiro $
#

######################################################################
# 文字列＋数値クラス定義
######################################################################
class StrVal < String
  def initialize(sStr, nVal = (sStr =~ /^[0-9]+$/) ? sStr.to_i() : nil)
    @nVal = nVal
    super(sStr)
  end

  # 数値情報を返す
  def val()
    return @nVal
  end

  # イレギュラーな使用時のエラー
  def unexpected_use(other, sExp)
    if (!@nVal.nil?)
      if (other.is_a?(StrVal) && other.val.nil?)
        error_exit("`#{other}' don't have value", caller[1])
      else
        error_exit("`#{sExp}' can't use with `#{other.class}'", caller[1])
      end
    else
      error_exit("`#{self}' don't have value", caller[1])
    end
  end

  # 演算子オーバーライド(tfと同等の機能を実現)
  alias_method :plus, :+
  alias_method :asterisk, :*
  alias_method :gt, :>
  alias_method :lt, :<
  alias_method :ge, :>=
  alias_method :le, :<=
  alias_method :eq, :==
  alias_method :ne, :!=
  alias_method :ls, :<<
  def +(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal + other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal + other.val
    else
      plus(other)
    end
  end
  def -(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal - other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal - other.val
    else
      unexpected_use(other, "-")
    end
  end
  def *(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal * other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal * other.val
    else
      asterisk(other)
    end
  end
  def /(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal / other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal / other.val
    else
      unexpected_use(other, "/")
    end
  end
  def &(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal & other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal & other.val
    else
      unexpected_use(other, "&")
    end
  end
  def |(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal | other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal | other.val
    else
      unexpected_use(other, "|")
    end
  end
  def >(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal > other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal > other.val
    else
      gt(other)
    end
  end
  def <(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal < other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal < other.val
    else
      lt(other)
    end
  end
  def >=(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal >= other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal >= other.val
    else
      ge(other)
    end
  end
  def <=(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal <= other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal <= other.val
    else
      le(other)
    end
  end
  def ==(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal == other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal == other.val
    else
      eq(other)
    end
  end
  def !=(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal != other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal != other.val
    else
      ne(other)
    end
  end
  def >>(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal >> other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal >> other.val
    else
      unexpected_use(other, ">>")
    end
  end
  def <<(other)
    if (!@nVal.nil? && other.is_a?(Integer))
      @nVal << other
    elsif (!@nVal.nil? && other.is_a?(StrVal) && !other.val.nil?)
      @nVal << other.val
    else
      ls(other)
    end
  end
  def ~@
    if (!@nVal.nil?)
      ~@nVal
    else
      unexpected_use(nil, "~")
    end
  end

  # ppデバッグ時の表示改善
  def pretty_print(q)
    if (!@nVal.nil?)
      q.text("#{self}{#{@nVal}(#{sprintf("0x%x",@nVal)})}")
    else
      q.text("#{self}{-}")
    end
  end
end

######################################################################
# 整数クラスの演算子オーバーライド(tfと同等の機能を実現)
######################################################################
class Fixnum
  alias_method :plus, :+
  alias_method :minus, :-
  alias_method :asterisk, :*
  alias_method :slash, :/
  alias_method :ampersand, :&
  alias_method :pipe, :|
  alias_method :gt, :>
  alias_method :lt, :<
  alias_method :ge, :>=
  alias_method :le, :<=
  alias_method :eq, :==
  alias_method :ne, :!=
  alias_method :rs, :>>
  alias_method :ls, :<<
  def +(other)
    other.is_a?(StrVal) ? plus(other.val) : plus(other)
  end
  def -(other)
    other.is_a?(StrVal) ? minus(other.val) : minus(other)
  end
  def *(other)
    other.is_a?(StrVal) ? asterisk(other.val) : asterisk(other)
  end
  def /(other)
    other.is_a?(StrVal) ? slash(other.val) : slash(other)
  end
  def &(other)
    other.is_a?(StrVal) ? ampersand(other.val) : ampersand(other)
  end
  def |(other)
    other.is_a?(StrVal) ? pipe(other.val) : pipe(other)
  end
  def >(other)
    other.is_a?(StrVal) ? gt(other.val) : gt(other)
  end
  def <(other)
    other.is_a?(StrVal) ? lt(other.val) : lt(other)
  end
  def >=(other)
    other.is_a?(StrVal) ? ge(other.val) : ge(other)
  end
  def <=(other)
    other.is_a?(StrVal) ? le(other.val) : le(other)
  end
  def ==(other)
    other.is_a?(StrVal) ? eq(other.val) : eq(other)
  end
  def !=(other)
    other.is_a?(StrVal) ? ne(other.val) : ne(other)
  end
  def >>(other)
    other.is_a?(StrVal) ? rs(other.val) : rs(other)
  end
  def <<(other)
    other.is_a?(StrVal) ? ls(other.val) : ls(other)
  end
end

class Bignum
  alias_method :plus, :+
  alias_method :minus, :-
  alias_method :asterisk, :*
  alias_method :slash, :/
  alias_method :ampersand, :&
  alias_method :pipe, :|
  alias_method :gt, :>
  alias_method :lt, :<
  alias_method :ge, :>=
  alias_method :le, :<=
  alias_method :eq, :==
  alias_method :ne, :!=
  alias_method :rs, :>>
  alias_method :ls, :<<
  def +(other)
    other.is_a?(StrVal) ? plus(other.val) : plus(other)
  end
  def -(other)
    other.is_a?(StrVal) ? minus(other.val) : minus(other)
  end
  def *(other)
    other.is_a?(StrVal) ? asterisk(other.val) : asterisk(other)
  end
  def /(other)
    other.is_a?(StrVal) ? slash(other.val) : slash(other)
  end
  def &(other)
    other.is_a?(StrVal) ? ampersand(other.val) : ampersand(other)
  end
  def |(other)
    other.is_a?(StrVal) ? pipe(other.val) : pipe(other)
  end
  def >(other)
    other.is_a?(StrVal) ? gt(other.val) : gt(other)
  end
  def <(other)
    other.is_a?(StrVal) ? lt(other.val) : lt(other)
  end
  def >=(other)
    other.is_a?(StrVal) ? ge(other.val) : ge(other)
  end
  def <=(other)
    other.is_a?(StrVal) ? le(other.val) : le(other)
  end
  def ==(other)
    other.is_a?(StrVal) ? eq(other.val) : eq(other)
  end
  def !=(other)
    other.is_a?(StrVal) ? ne(other.val) : ne(other)
  end
  def >>(other)
    other.is_a?(StrVal) ? rs(other.val) : rs(other)
  end
  def <<(other)
    other.is_a?(StrVal) ? ls(other.val) : ls(other)
  end
end
