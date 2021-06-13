#compdef m

# TODO: Based on targets given on the command line, show only variables that
# are used in those targets and their dependencies.

_m-expandVars() {
  local open close var val front='' rest=$1

  while [[ $rest == (#b)[^$]#($)* ]]; do
    front=$front${rest[1,$mbegin[1]-1]}
    rest=${rest[$mbegin[1],-1]}

    case $rest[2] in
      ($)	    # '$$'. may not appear in target and variable's value
	front=$front\$\$
	rest=${rest[3,-1]}
	continue
	;;
      (\()	    # Variable of the form $(foobar)
	open='('
	close=')'
	;;
      ({)	    # ${foobar}
	open='{'
	close='}'
	;;
      ([[:alpha:]]) # $foobar. This is exactly $(f)oobar.
	open=''
	close=''
	var=$rest[2]
	;;
      (*)	    # bad parameter name
	print -- $front$rest
	return 1
	;;
    esac

    if [[ -n $open ]]; then
      if [[ $rest == \$$open(#b)([[:alnum:]_]##)(#B)$close* ]]; then
	var=$match
      else  # unmatched () or {}, or bad parameter name
	print -- $front$rest
	return 1
      fi
    fi

    val=''
    if [[ -n ${VAR_ARGS[(i)$var]} ]]; then
      val=${VAR_ARGS[$var]}
    else
      if [[ -n $opt_args[(I)(-e|--environment-overrides)] ]]; then
	if [[ $parameters[$var] == scalar-export* ]]; then
	  val=${(P)var}
	elif [[ -n ${VARIABLES[(i)$var]} ]]; then
	  val=${VARIABLES[$var]}
	fi
      else
	if [[ -n ${VARIABLES[(i)$var]} ]]; then
	  val=${VARIABLES[$var]}
	elif [[ $parameters[$var] == scalar-export* ]]; then
	  val=${(P)var}
	fi
      fi
    fi
    rest=${rest//\$$open$var$close/$val}
  done

  print -- ${front}${rest}
}

_m-parseMakefile () {
  local input var val target dep TAB=$'\t' tmp IFS=

  while read input
  do
    case "$input " in
      # VARIABLE = value OR VARIABLE ?= value
      ([[:alnum:]][[:alnum:]_]#[" "$TAB]#(\?|)=*)
      var=${input%%[ $TAB]#(\?|)=*}
      val=${input#*=}
      val=${val##[ $TAB]#}
      VARIABLES[$var]=$val
      ;;

      # VARIABLE := value OR VARIABLE ::= value
      # Evaluated immediately
      ([[:alnum:]][[:alnum:]_]#[" "$TAB]#:(:|)=*)
      var=${input%%[ $TAB]#:(:|)=*}
      val=${input#*=}
      val=${val##[ $TAB]#}
      val=$(_m-expandVars $val)
      VARIABLES[$var]=$val
      ;;

      # TARGET: dependencies
      # TARGET1 TARGET2 TARGET3: dependencies
      ([[*?[:alnum:]$][^$TAB:=%]#:[^=]*)
      target=$(_m-expandVars ${input%%:*})
      TARGETS+=( ${(z)target} )
      ;;

      # Include another makefile
      (${~incl}" "*)
      local f=${input##${~incl} ##}
      if [[ $incl == '.include' ]]
      then
        f=${f#[\"<]}
        f=${f%[\">]}
      fi
      f=$(_m-expandVars $f)

      if [[ -r $f ]]
      then
        _m-parseMakefile < $f
      fi
      ;;
    esac
  done
}

_m-findBasedir () {
  local file index basedir
  basedir=$PWD
  for (( index=0; index < $#@; index++ ))
  do
    if [[ $@[index] == -C ]]
    then
      file=${~@[index+1]} 2>/dev/null
      if [[ -z $file ]]
      then
        # make returns with an error if an empty arg is given
        # even if the concatenated path is a valid directory
        return
      elif [[ $file == /* ]]
      then
        # Absolute path, replace base directory
        basedir=$file
      else
        # Relative, concatenate path
        basedir=$basedir/$file
      fi
    fi
  done
  print -- $basedir
}

_m() {

  local prev="$words[CURRENT-1]" file expl tmp is_gnu incl match
  local context state state_descr line
  local -a option_specs
  local -A VARIABLES VAR_ARGS opt_args
  local -aU TARGETS keys
  local ret=1

  # VAR=VAL on the current command line
  for tmp in $words; do
    if [[ $tmp == (#b)([[:alnum:]_]##)=(*) ]]; then
      VAR_ARGS[${tmp[$mbegin[1],$mend[1]]}]=${(e)tmp[$mbegin[2],$mend[2]]}
    fi
  done
  keys=( ${(k)VAR_ARGS} ) # to be used in 'compadd -F keys'

  _pick_variant -r is_gnu gnu=GNU unix -v -f

  if [[ $is_gnu == gnu ]]
  then
    incl="(-|)include"
    option_specs=()
  else
    # Basic make options only.
    incl=.include
    option_specs=()
  fi

  _arguments -s $option_specs \
    '*:make target:->target' && ret=0

  case $state in
    (dir)
    _description directories expl "$state_descr"
    _files "$expl[@]" -W ${(q)$(_m-findBasedir ${words[1,CURRENT-1]})} -/ && ret=0
    ;;

    (file)
    _description files expl "$state_descr"
    _files "$expl[@]" -W ${(q)$(_m-findBasedir $words)} && ret=0
    ;;

    (debug)
    _values -s , 'debug options' \
      '(b v i j m)a[all debugging output]' \
      'b[basic debugging output]' \
      '(b)v[one level above basic]' \
      '(b)i[describe implicit rule searches (implies b)]' \
      'j[show details on invocation of subcommands]' \
      'm[enable debugging while remaking makefiles]' && ret=0
    ;;

    (target)
    file=${(v)opt_args[(I)(-f|--file|--makefile)]}
    if [[ -n $file ]]
    then
      [[ $file == [^/]* ]] && file=${(q)$(_m-findBasedir $words)}/$file
      [[ -r $file ]] || file=
    else
      local basedir
      basedir=${$(_m-findBasedir $words)}
      if [[ $is_gnu == gnu && -r $basedir/GNUmakefile ]]
      then
        file=$basedir/GNUmakefile
      elif [[ -r $basedir/makefile ]]
      then
        file=$basedir/makefile
      elif [[ -r $basedir/Makefile ]]
      then
        file=$basedir/Makefile
      else
        file=''
      fi
    fi

    if [[ -n "$file" ]]
    then
      if [[ $is_gnu == gnu ]]
      then
        if zstyle -t ":completion:${curcontext}:targets" call-command; then
          _m-parseMakefile < <(_call_program targets "$words[1]" -nsp --no-print-directory -f "$file" .PHONY 2> /dev/null)
        else
          _m-parseMakefile < $file
        fi
      else
        if [[ $OSTYPE == (freebsd|dragonfly|netbsd)* || /$words[1] == */bmake* ]]; then
          TARGETS+=(${=${(f)"$(_call_program targets "$words[1]" -s -f "$file" -V.ALLTARGETS 2> /dev/null)"}})
          _m-parseMakefile < <(_call_program targets "$words[1]" -nsdg1Fstdout -f "$file" .PHONY 2> /dev/null)
        else
          _m-parseMakefile < $file
        fi
      fi
    fi

    if [[ $PREFIX == *'='* ]]
    then
      # Complete make variable as if shell variable
      compstate[parameter]="${PREFIX%%\=*}"
      compset -P 1 '*='
      _value "$@" && ret=0
    else
      _alternative \
        'targets:make target:compadd -Q -a TARGETS' \
        'variables:make variable:compadd -S = -F keys -k VARIABLES' && ret=0
    fi
  esac

  return ret
}

_m "$@"
