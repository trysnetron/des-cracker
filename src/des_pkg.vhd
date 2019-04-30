package des_pkg is
  subtype w28 is std_ulogic_vector(1 to 28);
  subtype w32 is std_ulogic_vector(1 to 32);
  subtype w48 is std_ulogic_vector(1 to 48);
  subtype w56 is std_ulogic_vector(1 to 56);
  subtype w64 is std_ulogic_vector(1 to 64);

  type ip_t is array(1 to 64) of natural;

  constant ip_table : ip_t := (...);

  function left_shift(w:w28; amount:natural) return w28;
  function right_shift(w:w28; amount:natural) return w28;

  function p(w:w32) return w32;
  function f(r:w32; rk: w48) return w32;
  function des(p:w64; k:w64) return w64;
  function ip(p:w64) return w64;

end package des_pkg;

package body des_pkg is
  
  function left_shift(w:w28; amount:natural) return w28 is
    if amount = 2 then
      return w(3 to 28) & w(1 to 2);
    elsif amount = 1 then
      return w(2 to 28) & w(1);
    else
      assert false report "ERROR" severity failure;
    end if;
  end left_shift;


  function right_shift(w:w28; amount:natural) return w28 is
    if amount = 2 then
      return w(27 to 28) & w(1 to 26);
    elsif amount = 1 then
      return w(28) & w(1 to 27);
    else
      assert false report "ERROR" severity failure;
    end if;
  end right_shift;


  function ip(p:w64) return w64 is
    variable result:w64;
  begin
    for i in 1 to 64 loop
      result(i) := w(ip_table(i));
    end loop;
    return result;
  end function;

end package body des_pkg;