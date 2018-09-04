(** Copyright (c) 2016-present, Facebook, Inc.

    This source code is licensed under the MIT license found in the
    LICENSE file in the root directory of this source tree. *)

open OUnit2

open Core

open Analysis
open Server
open Protocol
open Pyre
open Test


let test_parse_query _ =
  let assert_parses serialized query =
    assert_equal
      ~cmp:Request.equal
      (Request.TypeQueryRequest query)
      (Commands.Query.parse_query ~root:(mock_path "") serialized)
  in

  let assert_fails_to_parse serialized =
    try
      Commands.Query.parse_query ~root:(mock_path "") serialized
      |> ignore;
      assert_unreached ()
    with _ ->
      ()
  in

  assert_parses
    "less_or_equal(int, bool)"
    (LessOrEqual (Type.expression Type.integer, Type.expression Type.bool));
  assert_parses
    "less_or_equal (int, bool)"
    (LessOrEqual (Type.expression Type.integer, Type.expression Type.bool));
  assert_parses
    "less_or_equal(  int, int)"
    (LessOrEqual (Type.expression Type.integer, Type.expression Type.integer));

  assert_parses
    "Less_Or_Equal(  int, int)"
    (LessOrEqual (Type.expression Type.integer, Type.expression Type.integer));

  assert_parses
    "meet(int, bool)"
    (Meet (Type.expression Type.integer, Type.expression Type.bool));

  assert_parses
    "join(int, bool)"
    (Join (Type.expression Type.integer, Type.expression Type.bool));

  assert_parses
    "Join(int, bool)"
    (Join (Type.expression Type.integer, Type.expression Type.bool));

  assert_fails_to_parse "less_or_equal()";
  assert_fails_to_parse "less_or_equal(int, int, int)";
  assert_fails_to_parse "less_or_eq(int, bool)";

  assert_fails_to_parse "meet(int, int, int)";
  assert_fails_to_parse "meet(int)";

  assert_fails_to_parse "join(int)";
  assert_parses "superclasses(int)" (Superclasses (Type.expression Type.integer));
  assert_fails_to_parse "superclasses()";
  assert_fails_to_parse "superclasses(int, bool)";

  assert_parses "normalizeType(int)" (NormalizeType (Type.expression Type.integer));
  assert_fails_to_parse "normalizeType(int, str)";

  assert_equal
    (Commands.Query.parse_query ~root:(mock_path "") "typecheckPath(fiddle.py)")
    (Request.TypeCheckRequest
       (TypeCheckRequest.create
          ~check:[
            File.create (Path.create_relative ~root:(mock_path "") ~relative:"fiddle.py");
          ]
          ()
       ));

  assert_parses "type(C)" (Type (!"C"));
  assert_parses "type((C,B))" (Type (+(Ast.Expression.Tuple [!"C"; !"B"])));
  assert_fails_to_parse "type(a.b, c.d)";

  assert_fails_to_parse "typecheck(1+2)";

  assert_parses
    "type_at_location(a.py, 1, 2)"
    (TypeAtLocation {
        Ast.Location.path = "a.py";
        start = { Ast.Location.line = 1; column = 2 };
        stop = { Ast.Location.line = 1; column = 2 };
      });
  assert_fails_to_parse "type_at_location(a.py:1:2)";
  assert_fails_to_parse "type_at_location('a.py', 1, 2)";

  assert_parses "attributes(C)" (Attributes (Type.expression (Type.primitive "C")));
  assert_fails_to_parse "attributes(C, D)";

  assert_parses "signature(a.b)" (Signature (Ast.Expression.Access.create "a.b"));
  assert_fails_to_parse "signature(a.b, a.c)"


let () =
  "query">:::[
    "parse_query">::test_parse_query;
  ]
  |> run_test_tt_main
