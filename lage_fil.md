## Hvordan lage makefiler for vhdl prosjekter
Dette er test-tekst.
Makefiler med VHDL er visst en del vanskeligere enn makefiler i C fordi det ikke er slik at compileren lager en separat .o fil 
hver .vhd fil naar man typer make. Kompilatoren lager mange filer som man ikke nodvendigvis klarer aa holde styr paa. Maaten
vi kommer oss rundt dette er aa lage en .tag fil (for hver .vhd fil) som holder som oppdateres hver gang en .vhd fil kompileres.
Makefila vil se noe ut som dette:

```bash
VCOM:=vcom
VCOMFLAGS:= -2008
PHONY: all

SRC_DIR:=./src/
BUILD_DIR:= /tmp/some_where/ # Maa ikke vaere i /tmp

# Hovdefila som skal kompileres
all: des.tag

# Dersom build mappen ikke eksisterer
$(BUILD):
        mkdir $@

# Her sier vi at hver .tag fil i BUILD_DIR/ korresponderer til en .vhd fil i SRC_DIR/
$(BUILD_DIR)/%.tag: $(SRC_DIR)/%.vhd #| $(BUILD_DIR)
	$(VCOM) $(VCOMFLAGS) $<
	touch $@

# Eksempel paa deklarering av en dependency
$(BUILD)/des.tag: $(BUILD)/des_pkg.tag

```
