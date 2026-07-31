ROM := game.gb
OBJ := main.o

.PHONY: all clean

all: $(ROM)

$(OBJ): main.rgbasm hardware.rgbinc font.rgbasm
	rgbasm -Weverything -Werror -o $@ main.rgbasm

$(ROM): $(OBJ)
	rgblink --dmg --tiny -m game.map -n game.sym -o $@ $<
	rgbfix --title HELLO --pad-value 0 --validate $@

clean:
	rm -f $(ROM) $(OBJ) game.map game.sym
