"""Expose the project mission to the installed FotG without copying game assets."""
from pathlib import Path
project = Path(__file__).resolve().parent.parent
source = project/'missions/_SPT_A99_Aurore.fs2'
game = Path.home()/'Library/Application Support/io.github.KnossosNET.Knossos_NET/FreespaceOpen/FotG_R/FotG_R-1.1.2'
target = game/'data/missions/sp'/source.name
if target.is_symlink() and target.resolve() == source:
    print('Deja installee:', target)
elif target.exists() or target.is_symlink():
    raise SystemExit(f'Un fichier existe deja : {target}')
else:
    target.symlink_to(source)
    print('Mission installee:', target)
