# -*- coding: utf-8 -*-
#
#  Copyright (C) 2015 by Ushio Laboratory
#              Graduate School of Engineering Science, Osaka Univ., JAPAN
#  Copyright (C) 2015 by Embedded and Real-Time Systems Laboratory
#              Graduate School of Information Science, Nagoya Univ., JAPAN
# 

# require 'singleton'
# require 'set'

NotifierPluginArgProc = {
	"factory" => Proc.new { |obj, rhs| obj.set_factory(rhs) },
	"output_file" => Proc.new { |obj, rhs| obj.set_factory_output_file(rhs) }
}

class NotifierPlugin < CelltypePlugin

	# ------ 通知のハンドラの種類の定義 -------

	class Handler
		def initialize(call_port_name)
			@call_port_name = call_port_name
		end

		attr :call_port_name
	end

	# 通常のハンドラ
	EVENT_HANDLER = Handler::new("ciNotificationHandler")

	# エラーハンドラ (通常のハンドラが失敗した場合に呼び出される)
	ERROR_HANDLER = Handler::new("ciErrorNotificationHandler")

	HANDLERS = [
		EVENT_HANDLER,
		ERROR_HANDLER
	]

	class HandlerAttribute
		def initialize(name, error_name = nil)
			@name = name
			@error_name = error_name || (name + 'ForError')
		end

		def name_for_handler(handler)
			case handler
			when EVENT_HANDLER then return @name
			when ERROR_HANDLER then return @error_name
			else raise "unknown handler #{handler}"
			end
		end
	end

	# ------ 通知の属性の定義 -------
	# 
	# ハンドラタイプに合致しない属性が指定された場合に
	# エラーを出力できるよう、全ての属性をここで列挙する。

	SETVAR_ADDR_ATTR =   HandlerAttribute::new("setVariableAddress")
	SETVAR_VALUE_ATTR =  HandlerAttribute::new("setVariableValue")
	INCVAR_ADDR_ATTR =   HandlerAttribute::new("incrementedVariableAddress")
	SNDDTQ_VALUE_ATTR =  HandlerAttribute::new("dataqueueSentValue")
	SETFLG_FLAG_ATTR =   HandlerAttribute::new("flagPattern")

	ATTRS = [
		SETVAR_ADDR_ATTR,
		SETVAR_VALUE_ATTR,
		INCVAR_ADDR_ATTR,
		SNDDTQ_VALUE_ATTR,
		SETFLG_FLAG_ATTR
	]

	# ------ ハンドラタイプの定義 -------

	class BaseHandlerType
		# include Singleton

		def initialize()
			super

			# Set<HandlerAttribute>
			@required_attributes = [] # .to_set
		end

		attr :required_attributes

	    #=== NotifierPlugin#BaseHandlerType#validate_join
	    # 指定したセルの結合先が、このハンドラタイプに該当するかを検証
	    # handler:: Handler : ハンドラ
	    # cell:: Cell : セル
	    # join:: Join : 結合 (declarationがPortであるもの)
		def validate_join(handler, cell, join)
        	return !generate_attr_map(handler, cell).nil?
		end

	    #=== NotifierPlugin#BaseHandlerType#generate_attr_map
	    # 指定したセルの属性と、既知のHandlerAttributeのマッピングを
	    # 生成し、Hash<HandlerAttribute, Join> (各属性とそれに対応する
	    # Join(declarationがDeclのもの)を表すHash)、あるいは、
		# マッピングが行えない場合(属性の不足、過剰)はnilを返す。
	    # 
	    # handler:: Handler : ハンドラ
	    # cell:: Cell : セル
		def generate_attr_map(handler, cell)
			map = {}

			join_list = cell.get_join_list

			ATTRS.each { |known_attr|
				attr_name = known_attr.name_for_handler(handler)
				join = join_list.get_item(attr_name.to_sym)

				# このセルタイプにおいて必須の属性か?
				is_required = @required_attributes.include?(known_attr)

				# 属性の指定が不足している? or 過剰?
				# 注: ハンドラタイプの判別には、セルで値が指定されているか
				#     が考慮される。セルタイプで初期値が指定されていても、
				#     それはハンドラタイプの決定に影響しない。
				return nil if join.nil? != !is_required

				# 必要のない属性であり、指定もされていないので飛ばす
				next if join.nil?

				# TODO: attrの結合であることを検証

				map[known_attr] = join
			}

			return map
		end

	    #=== NotifierPlugin#BaseHandlerType#gen_cfg_handler_type
	    # タイムイベントの通知の種類を表すコンフィギュレータの記述を生成し、Stringまたはnilを返す
	    # handler:: Handler : ハンドラ
		def gen_cfg_handler_type(handler)
        	raise "called abstract method gen_cfg_handler_type"
		end

	    #=== NotifierPlugin#BaseHandlerType#gen_cfg_handler_parameters
	    # タイムイベントの通知の引数を表すコンフィギュレータの記述を生成し、String[]を返す
	    # handler:: Handler : ハンドラ
	    # join:: Join : 結合 (declarationがPortであるもの)
	    # attrMap:: Hash<HandlerAttribute, Join> : 
	    #     各属性とそれに対応するJoin (declarationがDeclのもの)
	    # cell:: Cell : セル
		def gen_cfg_handler_parameters(handler, join, attrMap, cell)
        	return nil
		end

	    #=== NotifierPlugin#BaseHandlerType#might_fail
	    # 通知の際、エラーが発生し、その結果エラー通知を呼ぶ必要が生じる
	    # かどうかを返す。
		def might_fail
			return false
		end

	end
	class BaseTaskHandlerType < BaseHandlerType
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				join && join.get_rhs_cell.get_celltype.get_name == :tTask
		end
		def gen_cfg_handler_parameters(handler, join, attrMap, cell)
			taskCell = join.get_cell
			id_attr_join = taskCell.get_join_list.get_item(:id)
			id_attr = join.get_rhs_cell.get_celltype.find(:id)
			if id_attr_join
				# セル生成時に初期化する場合
				id = id_attr_join.get_rhs.to_s
			else
				# セルタイプの初期化値を使う場合
				id = id_attr.get_initializer.to_s
			end

			# $id$等の置換
			name_array = taskCell.get_celltype.get_name_array(taskCell)
			id = taskCell.get_celltype.subst_name(id, name_array)

        	return [id]
		end
		def might_fail
			return true
		end
	end
	class ActivateTaskHandlerType < BaseTaskHandlerType
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				join.get_port_name == :eiActivateNotificationHandler
		end
		def gen_cfg_handler_type(handler)
			case handler
				when EVENT_HANDLER then return "TNFY_ACTTSK"
				when ERROR_HANDLER then return "TENFY_ACTTSK"
				else raise "unknown handler #{handler}"
			end
		end
	end
	class WakeUpTaskHandlerType < BaseTaskHandlerType
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				join.get_port_name == :eiWakeUpNotificationHandler
		end
		def gen_cfg_handler_type(handler)
			case handler
				when EVENT_HANDLER then return "TNFY_WUPTSK"
				when ERROR_HANDLER then return "TENFY_WUPTSK"
				else raise "unknown handler #{handler}"
			end
		end
	end
	class SetVariableHandlerType < BaseHandlerType
		def initialize()
			super
			@required_attributes = [
				SETVAR_ADDR_ATTR,
				SETVAR_VALUE_ATTR
			] # .to_set
		end
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				join.nil? && 
				handler == EVENT_HANDLER
		end
		def gen_cfg_handler_parameters(handler, join, attrMap, cell)
			var_addr = attrMap[SETVAR_ADDR_ATTR].get_rhs.to_s
			var_value = attrMap[SETVAR_VALUE_ATTR].get_rhs.to_s

			# $id$等の置換
			name_array = cell.get_celltype.get_name_array(cell)
			var_addr = cell.get_celltype.subst_name(var_addr, name_array)
			var_value = cell.get_celltype.subst_name(var_value, name_array)

        	return [var_addr, var_value]
		end
		def gen_cfg_handler_type(handler)
			case handler
				when EVENT_HANDLER then return "TNFY_SETVAR"
				else raise "unknown handler #{handler}"
			end
		end
	end
	class SetVariableToErrorCodeHandlerType < BaseHandlerType
		def initialize()
			super
			@required_attributes = [
				SETVAR_ADDR_ATTR
			] # .to_set
		end
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				join.nil? && 
				handler == ERROR_HANDLER
		end
		def gen_cfg_handler_parameters(handler, join, attrMap, cell)
			var_addr = attrMap[SETVAR_ADDR_ATTR].get_rhs.to_s

			# $id$等の置換
			name_array = cell.get_celltype.get_name_array(cell)
			var_addr = cell.get_celltype.subst_name(var_addr, name_array)

        	return [var_addr]
		end
		def gen_cfg_handler_type(handler)
			case handler
				when ERROR_HANDLER then return "TENFY_SETVAR"
				else raise "unknown handler #{handler}"
			end
		end
	end
	class IncrementVariableHandlerType < BaseHandlerType
		def initialize()
			super
			@required_attributes = [
				INCVAR_ADDR_ATTR
			] # .to_set
		end
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				join.nil?
		end
		def gen_cfg_handler_parameters(handler, join, attrMap, cell)
			var_addr = attrMap[INCVAR_ADDR_ATTR].get_rhs.to_s

			# $id$等の置換
			name_array = cell.get_celltype.get_name_array(cell)
			var_addr = cell.get_celltype.subst_name(var_addr, name_array)

        	return [var_addr]
		end
		def gen_cfg_handler_type(handler)
			case handler
				when EVENT_HANDLER then return "TNFY_INCVAR"
				when ERROR_HANDLER then return "TENFY_INCVAR"
				else raise "unknown handler #{handler}"
			end
		end
	end
	class SignalSemaphoreHandlerType < BaseHandlerType
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				join && join.get_rhs_cell.get_celltype.get_name == :tSemaphore
		end
		def gen_cfg_handler_parameters(handler, join, attrMap, cell)
			semaphoreCell = join.get_cell
			id_attr_join = semaphoreCell.get_join_list.get_item(:id)
			id_attr = join.get_rhs_cell.get_celltype.find(:id)
			if id_attr_join
				# セル生成時に初期化する場合
				id = id_attr_join.get_rhs.to_s
			else
				# セルタイプの初期化値を使う場合
				id = id_attr.get_initializer.to_s
			end

			# $id$等の置換
			name_array = semaphoreCell.get_celltype.get_name_array(semaphoreCell)
			id = semaphoreCell.get_celltype.subst_name(id, name_array)

        	return [id]
		end
		def might_fail
			return true
		end
		def gen_cfg_handler_type(handler)
			case handler
				when EVENT_HANDLER then return "TNFY_SIGSEM"
				when ERROR_HANDLER then return "TENFY_SIGSEM"
				else raise "unknown handler #{handler}"
			end
		end
	end
	class SetEventflagHandlerType < BaseHandlerType
		def initialize()
			super
			@required_attributes = [
				SETFLG_FLAG_ATTR
			] # .to_set
		end
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				join && join.get_rhs_cell.get_celltype.get_name == :tEventflag
		end
		def gen_cfg_handler_parameters(handler, join, attrMap, cell)
			eventflagCell = join.get_cell
			id_attr_join = eventflagCell.get_join_list.get_item(:id)
			id_attr = join.get_rhs_cell.get_celltype.find(:id)
			if id_attr_join
				# セル生成時に初期化する場合
				id = id_attr_join.get_rhs.to_s
			else
				# セルタイプの初期化値を使う場合
				id = id_attr.get_initializer.to_s
			end
			flg_pattern = attrMap[SETFLG_FLAG_ATTR].get_rhs.to_s

			# $id$等の置換
			name_array = eventflagCell.get_celltype.get_name_array(eventflagCell)
			id = eventflagCell.get_celltype.subst_name(id, name_array)

			name_array = cell.get_celltype.get_name_array(cell)
			flg_pattern = cell.get_celltype.subst_name(flg_pattern, name_array)

        	return [id, flg_pattern]
		end
		def might_fail
			return true
		end
		def gen_cfg_handler_type(handler)
			case handler
				when EVENT_HANDLER then return "TNFY_SETFLG"
				when ERROR_HANDLER then return "TENFY_SETFLG"
				else raise "unknown handler #{handler}"
			end
		end
	end
	class DataqueueHandlerType < BaseHandlerType
		def initialize()
			super
		end
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				join && join.get_rhs_cell.get_celltype.get_name == :tDataqueue
		end
		def gen_cfg_handler_parameters(handler, join, attrMap, cell)
			dataqueueCell = join.get_cell
			id_attr_join = dataqueueCell.get_join_list.get_item(:id)
			id_attr = join.get_rhs_cell.get_celltype.find(:id)
			if id_attr_join
				# セル生成時に初期化する場合
				id = id_attr_join.get_rhs.to_s
			else
				# セルタイプの初期化値を使う場合
				id = id_attr.get_initializer.to_s
			end

			# $id$等の置換
			name_array = dataqueueCell.get_celltype.get_name_array(dataqueueCell)
			id = dataqueueCell.get_celltype.subst_name(id, name_array)

			name_array = cell.get_celltype.get_name_array(cell)

        	return [id]
		end
		def might_fail
			return true
		end
	end
	class SendToDataqueueHandlerType < DataqueueHandlerType
		def initialize()
			super
			@required_attributes = [
				SNDDTQ_VALUE_ATTR
			] # .to_set
		end
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && handler == EVENT_HANDLER
		end
		def gen_cfg_handler_parameters(handler, join, attrMap, cell)
			params = super(handler, join, attrMap, cell)

			sent_value = attrMap[SNDDTQ_VALUE_ATTR].get_rhs.to_s

			# $id$等の置換
			name_array = cell.get_celltype.get_name_array(cell)
			sent_value = cell.get_celltype.subst_name(sent_value, name_array)

			params << sent_value

        	return params
		end
		def gen_cfg_handler_type(handler)
			case handler
				when EVENT_HANDLER then return "TNFY_SNDDTQ"
				else raise "unknown handler #{handler}"
			end
		end
	end
	class SendErrorCodeToDataqueueHandlerType < DataqueueHandlerType
		def initialize()
			super
		end
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && handler == ERROR_HANDLER
		end
		def gen_cfg_handler_type(handler)
			case handler
				when ERROR_HANDLER then return "TENFY_SNDDTQ"
				else raise "unknown handler #{handler}"
			end
		end
	end
	class UserHandlerType < BaseHandlerType
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				handler != ERROR_HANDLER && # invalid for error handler
				join && join.get_rhs_cell.get_celltype.get_name == :tTimeEventHandler
		end
		def gen_cfg_handler_type(handler)
			case handler
				when EVENT_HANDLER then return "TNFY_HANDLER"
				else raise "unknown handler #{handler}"
			end
		end
		def gen_cfg_handler_parameters(handler, join, attrMap, cell)
			uh_cell = join.get_rhs_cell

			# tTimeEventHandlerのCBへのポインタを取得
			name_array = uh_cell.get_celltype.get_name_array(uh_cell)
			cbp_of_uh = uh_cell.get_celltype.subst_name("$cbp$", name_array)

        	return [cbp_of_uh, "&tTimeEventHandler_start"]
		end
	end
	class NullHandlerType < BaseHandlerType
		def validate_join(handler, cell, join, *args)
			return super(handler, cell, join, *args) && 
				join.nil? &&
				handler != EVENT_HANDLER # handler is mandatory for normal handler!
		end
		def gen_cfg_handler_type(handler)
			case handler
				when ERROR_HANDLER then return nil
				else raise "unknown handler #{handler}"
			end
		end
	end

	HANDLER_TYPES = [
		# ActivateTaskHandlerType.instance,
		# WakeUpTaskHandlerType.instance,
		# SetVariableHandlerType.instance,
		# SetVariableToErrorCodeHandlerType.instance,
		# IncrementVariableHandlerType.instance,
		# SignalSemaphoreHandlerType.instance,
		# SetEventflagHandlerType.instance,
		# SendToDataqueueHandlerType.instance,
		# SendErrorCodeToDataqueueHandlerType.instance,
		# UserHandlerType.instance,
		# NullHandlerType.instance
		ActivateTaskHandlerType.new,
		WakeUpTaskHandlerType.new,
		SetVariableHandlerType.new,
		SetVariableToErrorCodeHandlerType.new,
		IncrementVariableHandlerType.new,
		SignalSemaphoreHandlerType.new,
		SetEventflagHandlerType.new,
		SendToDataqueueHandlerType.new,
		SendErrorCodeToDataqueueHandlerType.new,
		UserHandlerType.new,
		NullHandlerType.new
	]

    #@celltype:: Celltype
    #@option:: String     :オプション文字列
    def initialize( celltype, option )
    	super
    	@plugin_arg_check_proc_tab = NotifierPluginArgProc
    	@plugin_arg_str = option
    	@plugin_arg_str = option.gsub( /\A"(.*)/, '\1' )    # 前後の "" を取り除く
    	@plugin_arg_str.sub!( /(.*)"\z/, '\1' )
    	@factory = nil
    	@output_file = nil
    	parse_plugin_arg
    	unless @factory
    		cdl_error("ASP1003 celltype $1: option factory is not specified",
    			celltype.get_name)
    	end
    	unless @output_file
    		cdl_error("ASP1003 celltype $1: option output_file is not specified",
    			celltype.get_name)
    	end
    end

    def set_factory(template_string)
    	unless @factory.nil?
    		cdl_error("ASP1003 celltype $1: option factory was specified more than once",
    			celltype.get_name)
    	end
    	@factory = template_string
    end

    def set_factory_output_file(output_file)
    	unless @output_file.nil?
    		cdl_error("ASP1003 celltype $1: option output_file was specified more than once",
    			celltype.get_name)
    	end
    	@output_file = output_file
    end

    def gen_factory file
        puts "===== begin #{@celltype.get_name.to_s} plugin ====="

        kernelCfg = AppFile.open( "#{$gen}/#{@output_file}" )
        kernelCfg.print "\n/* Generated by #{self.class.name} */\n\n"

    	# 属性置換が行えることを検証する。
    	# ここで行うのは、factoryで指定された属性名が
    	# 存在することを確認し、しなければエラーを出力することのみである。
    	# セルごとの処理の最中にエラーを出力することも可能ではあるが、
    	# そうするとセルタイプ側の問題であるのにもかかわらず、セルごとに
    	# エラーが表示されてしまう。
    	# {{attribute_name}} -> attribute_value
    	@factory.scan(/\{\{([a-zA-Z0-9_]*?)\}\}/) { |match|
    		name = $1.to_sym

    		# {{_handler_params_}} はハンドラに関する指定。プラグイン内で値が生成される
    		next if name == :_handler_params_

			subst_attr = @celltype.find(name)
			unless subst_attr
	    		cdl_error( "ASP1007 celltype $1: additional_param: attribute $2 does not exist.", 
	    			@celltype.get_name, name)
			end
		}

        @celltype.get_cell_list.each { |cell|
        	gen_factory_for_cell kernelCfg, cell
        }

        kernelCfg.close
        puts "===== end #{@celltype.get_name.to_s} plugin ====="
    end

    def gen_factory_for_cell(kernelCfg, cell)
    	handler_flags = []
    	handler_args = []

    	event_handler_might_fail = true
    	handler_flag = nil

		# ignoreErrorsを取得
		ignoreErrors_attr_join = cell.get_join_list.get_item(:ignoreErrors)
		ignoreErrors_attr = cell.get_celltype.find(:ignoreErrors)
		if ignoreErrors_attr_join
			# セル生成時に初期化する場合
			ignoreErrors = ignoreErrors_attr_join.get_rhs.to_s
		else
			# セルタイプの初期化値を使う場合
			ignoreErrors = ignoreErrors_attr.get_initializer.to_s
		end
		case ignoreErrors
			when 'true' then ignoreErrors = true
			when 'false' then ignoreErrors = false
			else
				cdl_warning( "ASP1005 cell $1: unrecognized value '$2' specified for ignoreErrors",
					cell.get_name, ignoreErrors )
				ignoreErrors = false
		end

    	[EVENT_HANDLER, ERROR_HANDLER].each { |handler|
    		# 呼び口の結合を取得
    		call_join = cell.get_join_list.get_item(handler.call_port_name.to_sym)

    		if !handler_flag.nil?
    			# 通知ハンドラで「エラーが発生するはずがない」のに「エラーハンドラが指定されている」
    			# もしくはその逆のパターンを検出する。
    			# (handler_flagがnilである場合、ハンドラタイプが不明であり、エラーが発生するか不明
    			#  なため、検出は行わない。)
	    		if handler == ERROR_HANDLER && !call_join.nil? && !event_handler_might_fail
		    		cdl_error( "ASP1004 cell $1: handler type $2 which never raises an error was inferred for cNotificationHandler, but cErrorNotificationHandler is joined .", 
		    			cell.get_name, handler_flag)
	    		end
	    		if handler == ERROR_HANDLER && call_join.nil? && event_handler_might_fail && !ignoreErrors
		    		cdl_warning( "ASP1006 cell $1: handler type $2 which might raise an error was inferred for cNotificationHandler, but cErrorNotificationHandler is not joined.", 
		    			cell.get_name, handler_flag)
	    		end
	    	end

	    	# ハンドラタイプを判別する
	    	matches = HANDLER_TYPES.select { |handler_type|
	    		handler_type.validate_join(handler, cell, call_join)
	    	}

	    	if matches.length == 0
	    		cdl_error( "ASP1001 cell $1: no matching handler type found for $2", cell.get_name, handler.call_port_name )
	    		next
	    	end

	    	ht = matches[0]

	    	unless ht.validate_join(handler, cell, call_join)
	    		raise "!validate_join"
	    	end

	    	handler_flag = ht.gen_cfg_handler_type(handler)
	    	handler_flags << handler_flag if handler_flag

	    	attr_map = ht.generate_attr_map(handler, cell)

	    	handler_arg = ht.gen_cfg_handler_parameters(handler, call_join, attr_map, cell)
	    	handler_args += handler_arg if handler_arg

	    	if handler == EVENT_HANDLER
	    		event_handler_might_fail = ht.might_fail
	    	end
    	}

    	# idを取得
		id_attr_join = cell.get_join_list.get_item(:id)
		id_attr = cell.get_celltype.find(:id)
		if id_attr_join
			# セル生成時に初期化する場合
			id = id_attr_join.get_rhs.to_s
		else
			# セルタイプの初期化値を使う場合
			id = id_attr.get_initializer.to_s
		end

		# attributeを取得
		attribute_attr_join = cell.get_join_list.get_item(:attribute)
		attribute_attr = cell.get_celltype.find(:attribute)
		if attribute_attr_join
			# セル生成時に初期化する場合
			attribute = attribute_attr_join.get_rhs.to_s
		else
			# セルタイプの初期化値を使う場合
			attribute = attribute_attr.get_initializer.to_s
		end

		# $id$等の置換
		name_array = cell.get_celltype.get_name_array(cell)
		id = cell.get_celltype.subst_name(id, name_array)
		attribute = cell.get_celltype.subst_name(attribute, name_array)
		handler_args.collect! { |e|
			if e == "$cbp$"
				cell.get_celltype.subst_name(e, name_array)
			else
				e
			end
		}

    	# tecsgen.cfgの記述を生成する。
    	# factoryに対し、パラメータ置換を行う。
    	# {{attribute_name}} -> attribute_value
    	text = @factory.gsub(/\{\{([a-zA-Z0-9_]*?)\}\}/) { |match|
    		name = $1.to_sym
			subst_attr = cell.get_celltype.find(name)

			# {{_handler_params_}} はハンドラの指定に置換する。
			if name == :_handler_params_
		    	args_joined = handler_flags.join(' | ')
		    	if handler_args.length > 0
			    	args_joined << ", "
			    	args_joined << handler_args.join(', ')
			    end
			    next args_joined
			end

			unless subst_attr
				# 属性が見つからないというエラーはすでに報告されているので
				# ここではダミー値を返しておくだけである。
				next ""
			end

			subst_attr_join = cell.get_join_list.get_item(name)
			if subst_attr_join
				# セル生成時に初期化する場合
				subst = subst_attr_join.get_rhs.to_s
			else
				# セルタイプの初期化値を使う場合
				subst = subst_attr.get_initializer.to_s
			end

			# $id$等の置換
			cell.get_celltype.subst_name(subst, name_array)
    	}
	    
    	# 出力
    	kernelCfg.puts text

    end
    private :gen_factory_for_cell

end
