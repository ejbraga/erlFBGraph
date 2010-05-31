== erlFBGraph

-----------------------------
== Description:

erlFBGraph was developed with the intent to be an Erlang client to Facebook Graph API.

It supports OAuth authentication, by simulating the HTTP packets involved in the interaction with the server to get the access token.

All the methods for getting data are contemplated.

-----------------------------
== Dependencies:

This module requires mochijson2 to parse JSON objects and mochixpath to parse XML.

-----------------------------
== Tutorial:

$ erl -pa /path/to/mochiweb/ebin/ -pa /path/to/mochixpath/ebin/
Erlang R13B04 (erts-5.7.5) [source] [smp:2:2] [rq:2] [async-threads:0] [hipe] [kernel-poll:false]

Eshell V5.7.5  (abort with ^G)
1> Token = erlFBGraph:get_token(Email, Password, Application_ID).
"128584520491486%7C2.ok4n7ERw_N0o2Y1vxa28ow__.3600.1275307200-100000373587590%7CnVe3bRTnvYs99z9_vApPVbX5ioc."

2> erlFBGraph:get_connection_data({"friends", Token}).
{struct,[{<<"data">>,
          [{struct,[{<<"name">>,<<"John Doe">>},
                    {<<"id">>,<<"123456">>}]}, 
           {...}|...]}]}

3> erlFBGraph:get_object_data({page, "cocacola", Token}).
{struct,[{<<"id">>,<<"40796308305">>},
         {<<"name">>,<<"Coca-Cola">>},
         {<<"picture">>,
          <<"http://profile.ak.fbcdn.net/object3/1853/100/s40796308305_2334.jpg">>},
         {<<"link">>,<<"http://www.facebook.com:443/coca-cola">>},
         {<<"category">>,<<"Consumer_products">>},
         {<<"username">>,<<"coca-cola">>},
         {<<"products">>,
          <<"Coca-Cola is the most popular and biggest-selling soft drink in history,"...>>},
         {<<"fan_count">>,5670228}]}

-----------------------------
== Acknowledgements:

Thanks to ngerakines for the development of erlang_facebook that inspired me to develop this module.