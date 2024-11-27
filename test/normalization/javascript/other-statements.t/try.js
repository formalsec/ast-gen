// try-catch statement with an empty body and catch
try { } catch { }
// try-finally statement with an empty body and catch
try { } finally { }
// try-catch-finally statement with an empty body and catch
try { } catch { } finally { }
// try-catch statement with a non-empty body and catch
try { x; } catch { y; }
// try-finally statement with a non-empty body and catch
try { x; } finally { y; }
// try-catch-finally statement with an non-empty body and catch
try { x; } catch { y; } finally { z; }
// try-finally statement with a nested try-catch
try { try { x; } catch { y; } } finally { z; }
// try-catch statement with a catch parameter
try { x } catch (foo) { y };
// try-catch statement with a catch object pattern parameter 
try { x; } catch ({ foo, bar: { baz } }) { y; }
// try-catch statement with a catch object pattern parameter with default values 
try { x; } catch ({ foo = 10, bar: { baz } = { baz: "abc" } }) { y; }
// try-catch statement with a catch array pattern parameter 
try { x; } catch ([foo, [bar, baz]]) { y; }
// try-catch statement with a catch array pattern parameter with default values
try { x; } catch ([foo = 10, [bar, baz] = ["abc", true]]) { y; }
