return function (URL)
    return loadstring(http.get(URL).readAll())()
end