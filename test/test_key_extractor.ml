let test_url ~name ~url ~expected =
  let actual = Cs_api_core.parse_s3_url url in
  ( name
  , `Quick
  , fun () -> Alcotest.(check (result string string) name expected actual) )

let test_body ~name ~body ~expected =
  let actual = Cs_api_core.parse_s3_response ~body in
  ( name
  , `Quick
  , fun () -> Alcotest.(check (result string string) name expected actual) )

let tests =
  [ test_url ~name:"Valid PUT URL"
      ~url:
        "http://localhost:9000/cryptosense-traces/uploads/eef240c643d040ffbcef622109946ae2?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=qwj4SgY1pZw2I0Bg/20230503/us-east-1/s3/aws4_request&X-Amz-Date=20230503T083920Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=f1415c31ddc23516a5535f28cfbee4269b461a085dd895820ca525be9f63d419"
      ~expected:(Ok "uploads/eef240c643d040ffbcef622109946ae2")
  ; test_url ~name:"Invalid PUT URL" ~url:"nonsense"
      ~expected:(Error "Key could not be extracted from S3 URL.")
  ; test_body ~name:"Valid body"
      ~body:
        {|
<?xml version="1.0" encoding="UTF-8"?>
<PostResponse><Bucket>cryptosense-traces</Bucket><Key>uploads/784f2aa928404db3a958fbd779a44156</Key><ETag>&#34;82887f4dd13a80e182aa01efc0a59e9e&#34;</ETag><Location>http://localhost:9000/cryptosense-traces/uploads/784f2aa928404db3a958fbd779a44156</Location></PostResponse>
    |}
      ~expected:(Ok "uploads/784f2aa928404db3a958fbd779a44156")
  ; test_body ~name:"Valid SeaweedFS body"
      ~body:
        {|
<?xml version="1.0" encoding="UTF-8"?>
<PostResponse><Location xmlns="http://s3.amazonaws.com/doc/2006-03-01/"></Location><Bucket xmlns="http://s3.amazonaws.com/doc/2006-03-01/">storage-traces</Bucket><Key xmlns="http://s3.amazonaws.com/doc/2006-03-01/">uploads/48db212785054589966f84565a263e90</Key><ETag xmlns="http://s3.amazonaws.com/doc/2006-03-01/">&#34;4425e01772cfdca990eff5f085d05414&#34;</ETag></PostResponse>
    |}
      ~expected:(Ok "uploads/48db212785054589966f84565a263e90")
  ; test_body ~name:"Invalid body" ~body:"This\ndoes not\ncontain a key."
      ~expected:(Error "Key could not be extracted from S3 response.") ]
