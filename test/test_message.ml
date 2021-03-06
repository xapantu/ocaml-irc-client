open OUnit

module H = Irc_helpers
module M = Irc_message

let pp_strlist l = "[" ^ String.concat ";" l ^ "]"

let test_split =
  let test1 () =
    assert_equal ~printer:pp_strlist
      ["ab"; "c"; "d"; "ef"]
      (H.split ~str:"ab c d ef" ~c:' ')
  and test2 () =
    assert_equal ~printer:pp_strlist
      [""; "a"; ""; "b"; "hello"; "world"; ""]
      (H.split ~str:" a  b hello world " ~c:' ')
  in
  "test_split" >:::  [ "1" >:: test1; "2" >:: test2 ]

let test_extract_prefix =
  let test ~msg ~input ~expected_output () =
    let parsed = M.extract_prefix input in
    assert_equal ~msg parsed expected_output
  in
  "test_extract_prefix" >:::
    [
      "test_no_prefix" >::
        test ~msg:"Parsing a message with no prefix"
          ~input:"PING :server.com"
          ~expected_output:(None, "PING :server.com");
      "test_prefix" >::
        test ~msg:"Parsing a message with a prefix"
          ~input:":nick!user@host PRIVMSG destnick :abc def"
          ~expected_output:(Some "nick!user@host", "PRIVMSG destnick :abc def");
    ]

let test_extract_trail =
  let test ~msg ~input ~expected_output () =
    let parsed = M.extract_trail input in
    assert_equal ~msg parsed expected_output
  in
  "test_extract_trail" >:::
    [
      "test_no_trail" >::
        test ~msg:"Parsing a message with no trail"
          ~input:"PING"
          ~expected_output:("PING", None);
      "test_trail1" >::
        test ~msg:"Parsing a message with a trail"
          ~input:"PING :irc.domain.com"
          ~expected_output:("PING", Some "irc.domain.com");
      "test_trail2" >::
        test ~msg:"Parsing a message with a trail and parameters"
          ~input:"PRIVMSG destnick :hi there"
          ~expected_output:("PRIVMSG destnick", Some "hi there");
    ]

let test_full_parser =
  let test ~msg ~input ~expected_output () =
    let parsed = M.parse input in
    assert_equal ~msg parsed expected_output
  in
  "test_full_parser" >:::
    [
      "test_parse_ping" >::
        test ~msg:"Parsing a PING message"
          ~input:"PING :abc.def"
          ~expected_output:(`Ok {
            M.prefix = None;
            command = M.PING "abc.def";
          });
      "test_parse_privmsg" >::
        test ~msg:"Parsing a PRIVMSG"
          ~input:":nick!user@host.com PRIVMSG #channel :Hello all"
          ~expected_output:(`Ok {
            M.prefix = Some "nick!user@host.com";
            command = M.PRIVMSG ("#channel", "Hello all");
          });
    ]

let suite =
  "test_message" >:::
    [
      test_split;
      test_extract_prefix;
      test_extract_trail;
      test_full_parser;
    ]
