-module(r2j_type_tests).

-ifdef(TEST).
-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").

proper_test_() ->
    Exported = ?MODULE:module_info(exports),
    Exported1 = lists:filter(fun
        ({Atom, 0}) ->
            case atom_to_list(Atom) of
                "prop_" ++ _ -> true;
                _ -> false
            end;
        (_) ->
            false
    end, Exported),
    Exported2 = [F || {F, _} <- Exported1],
    proper_test_gen(Exported2).

proper_test_gen([]) ->
    {generator, fun() -> [] end};
proper_test_gen([ProperTest | Tail]) ->
    {generator, fun() -> [
        {atom_to_list(ProperTest), fun() ->
            ?assert(proper:quickcheck(erlang:apply(?MODULE, ProperTest, []), 100))
        end} |
        proper_test_gen(Tail) ]
    end}.

%% proper funcs.
prop_integer() ->
    ?FORALL(Val, oneof([int(), real()]),
		begin
		    Got = r2j_type:integer(Val),
				Expected = if
				    is_integer(Val) ->
				        {ok, Val};
						true ->
						    error
				end,
				Expected == Got
		end).

prop_integer_min_max() ->
    ?FORALL({Min, Length, Val}, {int(), int(), oneof([int(), real(), <<"bin">>])},
		begin
        Max = Min + Length,
				Expected = if
				    is_integer(Val) andalso Min =< Val andalso Val =< Max ->
						    {ok, Val};
						true ->
						    error
				end,
				Got = r2j_type:integer(Val, Min, Max),
				Expected == Got
		end).

prop_string() ->
    ?FORALL({Val, MaybeLen}, {binary(), int()},
		begin
        Len = abs(MaybeLen),
				Expected = if
				    size(Val) =< Len ->
						    {ok, Val};
						true ->
						    error
				end,
				Got = r2j_type:string(Val, Len),
				Expected == Got
		end).

-endif.
