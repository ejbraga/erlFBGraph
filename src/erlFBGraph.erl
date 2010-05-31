-module(erlFBGraph).
-author("Emanuel Braga <braga.emanuel@gmail.com>").
-copyright('Copyright (c) 2010 Emanuel Braga').
% -version(0.0).

%% API
-export([
   get_token/3,
   get_object_data/1,
   get_connection_data/1
   ]).

%% ---------------------

-import(mochijson2).
-import(mochiweb_xpath).

-define(GRAPH_URL, "https://graph.facebook.com/").
-define(AUTHORIZE_URL, "https://graph.facebook.com/oauth/authorize").
-define(TOKEN_URL, "https://graph.facebook.com/oauth/access_token").


%% Methods

get_token(Email, Password, APP_ID) ->
   init_services(),

   User_agent = "Mozilla/5.0 (X11; U; Linux i686; pt-PT; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3",

   http:set_options([{cookies, enabled}]),

   Body = case http:request(get, {"https://graph.facebook.com/oauth/authorize?client_id=" ++ APP_ID ++ "&redirect_uri=http://www.facebook.com/connect/login_success.html&type=user_agent&display=popup", [{"User-Agent", User_agent}]}, [], []) of
      {ok, {{_Version, 200, _ReasonPhrase}, _Headers, Body1}} ->
         Body1;
      {error, Reason} ->
         throw({error, Reason})
   end,

   % parse html to get the login link
   Tree = mochiweb_html:parse(Body),
   Login_link = get_login_link(Tree),

   Next = get_attribute(Tree, "next"),
   Return_session = get_attribute(Tree, "return_session"),
   Session_key_only = get_attribute(Tree, "session_key_only"),
   Skip_api_login = get_attribute(Tree, "skip_api_login"),
   Trynum = get_attribute(Tree, "trynum"),
   Version = get_attribute(Tree, "version"),
   API_key = get_attribute(Tree, "api_key"),
   Cancel_url = get_attribute(Tree, "cancel_url"),
   Legacy_return = get_attribute(Tree, "legacy_return"),
   Display = get_attribute(Tree, "display"),
   LSD = get_attribute(Tree, "lsd"),

   % get the referer
   Referer = "http://www.facebook.com/login.php?" ++ "api_key=" ++ API_key ++ "&display=" ++ Display ++ "&cancel_url=" ++ Cancel_url ++ "&skip_api_login=" ++ Skip_api_login ++ "&fbconnect=1" ++ "&from_login=1&return_session=1" ++ "&next=" ++ Next,

   % send login data to server
   Credentials = "email=" ++ Email ++ "&pass=" ++ Password,

   % Without the 'next' and 'cancel_url' attributes
   Other_args = "&return_session=" ++ Return_session ++ "&session_key_only=" ++ Session_key_only ++ "&skip_api_login=" ++ Skip_api_login ++ "&trynum=" ++ Trynum ++ "&version=" ++ Version ++ "&api_key=" ++ API_key ++ "&legacy_return=" ++ Legacy_return ++ "&display=" ++ Display ++ "&lsd=" ++ LSD ++ "&from_login=1",

   Headers2 = case http:request(post, {Login_link, [{"User-Agent", User_agent}, {"Rererer", Referer}], [], Credentials ++ Other_args }, [], []) of
      {ok, {{_Version2, _Code2, _ReasonPhrase2}, Headers, _Body2}} ->
         Headers;
      {error, Reason2} ->
         throw({error, Reason2})
   end,

   % parse header to get the location_parameter
   [Location] = parse_header(Headers2, "location", []),

   % get access_token link
   Body3 = case http:request(get, {Location, [{"User-Agent", User_agent}]}, [], []) of
      {ok, {{_Version3, 200, _ReasonPhrase3}, _Headers3, Body4}} ->
         Body4;
      {error, Reason3} ->
         throw({error, Reason3})
   end,

   % parse the body to get the access token
   Tree3 = mochiweb_html:parse(Body3),
   URL_token = get_token_url(Tree3),
   [_Dont_care, Token] = string:tokens(URL_token, "="),

   Token.


%% @private
%% @edoc Parse Header to get a given attribute
parse_header([], _Attrb, Ac) ->
   Ac;

parse_header([H | T], Attrib, Ac) ->
   case H of
      {Attrib, X} ->
         parse_header(T, Attrib, lists:append(Ac, [X]));
      _ ->
         parse_header(T, Attrib, Ac)
   end.

%% @private
%% @edoc Parse the HTML code to get the url with the token
get_token_url(Tree) ->
   XPath = "//link[@rel='alternate']/@href",
   [Link] = mochiweb_xpath:execute(XPath, Tree),
   to_text(Link).

%% @private
%% @edoc Parse HTML to get the login page
get_login_link(Tree) ->
   XPath = "//form[@id='login_form']/@action",
   [Link] = mochiweb_xpath:execute(XPath, Tree),
   to_text(Link).

%% @private
%% @edoc Parse HTML to get specified attribute
get_attribute(Tree, Attribute) ->
   XPath = "//input[@id='" ++ Attribute ++ "']/@value",
   [Next] = mochiweb_xpath:execute(XPath, Tree),
   to_text(Next).


%% @private
%% @edoc Init services
init_services() ->
   % start inets
   try inets:start() of
      ok -> ok;
      {error,{already_started,inets}} -> ok
   catch
      {error,{already_started,inets}} -> ok;
      throw:X -> {"", caught, thrown, X};
      exit:X -> {"", caught, exited, X};
      error:X -> {"", caught, error, X}
   end,
   % start ssl
   try ssl:start() of
      ok -> ok;
      {error,{already_started,ssl}} -> ok
   catch
      {error,{already_started,inets}} -> ok;
      throw:X2 -> {"", caught, thrown, X2};
      exit:X2 -> {"", caught, exited, X2};
      error:X2 -> {"", caught, error, X2}
   end.

%% @private
%% @edoc If the argument is binary returns it into a list
to_text(Arg) when is_binary(Arg) ->
   binary_to_list(Arg).


%% -----------------------------------------------------------------------

%% @edoc Fetches objects' data
get_object_data(Arg) ->
   init_services(),
   {Type, ID, AccessToken} = Arg,
   case atom_to_list(Type) of
      "user" ->
         URL = build_object_URL(ID, AccessToken),
         Data_json = send_request(URL),
         Data = mochijson2:decode(Data_json),
         Data;
      "page" ->
         URL = build_object_URL(ID, AccessToken),
         Data_json = send_request(URL),
         Data = mochijson2:decode(Data_json),
         Data;
      "event" ->
         URL = build_object_URL(ID, AccessToken),
         Data_json = send_request(URL),
         Data = mochijson2:decode(Data_json),
         Data;
      "group" ->
         URL = build_object_URL(ID, AccessToken),
         Data_json = send_request(URL),
         Data = mochijson2:decode(Data_json),
         Data;
      "application" ->
         URL = build_object_URL(ID, AccessToken),
         Data_json = send_request(URL),
         Data = mochijson2:decode(Data_json),
         Data;
      "status_message" ->
         URL = build_object_URL(ID, AccessToken),
         Data_json = send_request(URL),
         Data = mochijson2:decode(Data_json),
         Data;
      "photo" ->
         URL = build_object_URL(ID, AccessToken),
         Data_json = send_request(URL),
         Data = mochijson2:decode(Data_json),
         Data;
      "photo_album" ->
         URL = build_object_URL(ID, AccessToken),
         Data_json = send_request(URL),
         Data = mochijson2:decode(Data_json),
         Data;
      "video" ->
         URL = build_object_URL(ID, AccessToken),
         Data_json = send_request(URL),
         Data = mochijson2:decode(Data_json),
         Data;
      "note" ->
         URL = build_object_URL(ID, AccessToken),
         Data_json = send_request(URL),
         Data = mochijson2:decode(Data_json),
         Data;
      _ -> throw({error})
   end.

%% @edoc Fetches connections' data
get_connection_data(Arg) ->
   init_services(),
   {Connection, AccessToken} = Arg,
   URL = build_connection_URL(Connection, AccessToken),
   Data_json = send_request(URL),
   Data = mochijson2:decode(Data_json),
   Data.


%% @private
%% @edoc Builds the URL to fetche objects' data
build_object_URL(ID, Token) ->
   URL = ?GRAPH_URL ++ ID ++ "?access_token=" ++ Token,
   URL.

%% @private
%% @edoc Builds the URL to fetche connections' data
build_connection_URL(Connection, Token) ->
   URL = ?GRAPH_URL ++ "me/" ++ Connection ++ "?access_token=" ++ Token,
   URL.

%% @private
%% @edoc Sends the request to Facebook Graph API
send_request(URL) ->
   try http:request(get, {URL, []}, [], []) of
      {ok, {{_Version, 200, _ReasonPhrase}, _Headers, Body}} -> Body;
      Other -> throw({{Other}})
   catch
      throw:X -> {URL, caught, thrown, X};
      exit:X -> {URL, caught, exited, X};
      error:X -> {URL, caught, error, X}
   end.
