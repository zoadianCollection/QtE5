module qte5prs;

import asc1251 : fromUtf8to1251;
import std.string : translate, split, strip, indexOf, toLower;
private import std.stdio; // : File;

// Должен быть объект, получающий на вход строку. Строка раскладываается
// на состовные слова и запоминается в поисковике. Список слов может
// быть найден (выдан) по входной последовательности

// ==================================================================
// CFinder - поисковик
// ==================================================================
// __________________________________________________________________
class CFinder { //=> Поисковик. Помнит все слова в файле
	alias fNode* un; // Ссылка на узел цепочки
	// ______________________________________________________________
	this() {
	}
	// ______________________________________________________________
	~this() {
	}
	// ______________________________________________________________
	private struct fNode { //-> Узел списка гирлянды
		un	 		link;		// Указатель на следующий или null
		string 		str;		// Строка (слово)
	}
	// ______________________________________________________________
	private un[256] harrow; 	//-> гребенка, для 256 списков слов
	dchar[dchar] transTable1;
	un[]  masAllWords;			// Список указателей на все слова
	// ______________________________________________________________
	ubyte getC0(string s) { //-> Выдать индекс в гребенке
		import std.utf: stride;
		if(s.length == 0) return 0;
		char[] w1251 = fromUtf8to1251(cast(char[])s[0..stride(s, 0)]);
		return w1251[0];
	}
	// ______________________________________________________________
	void addWord(string w) { //-> Добавить слово в список, если его нет
		if(w.length == 0) return;
		ubyte c0;
		if(!isWordMono(w)) {
			c0 = getC0(w);	// Первая буква слова, как индекс цепочки в harrow
			// Создадим узел цепочки (списка)
			un nod = new fNode;  nod.str = w;
			masAllWords ~= nod;		// Запомним это слово в полном списке слов
			nod.link = harrow[c0];	// Вставим новый узел в цепочку
			harrow[getC0(w)] = nod;	// Подвесим обновленную цепочку
/* 			
			// Надо идти по цепочке и удалять все производные слова
			int dlw = w.length, dln;
			un ukaz  = nod, ukaz0 = ukaz;
			while(!(ukaz is null)) {
				dln = ukaz.str.length;
				if(dln < dlw) {
					// Найденное слово короче вставленного слова
					if(w[0 .. dln] == ukaz.str) {
						// Удаляем этот элемент
						ukaz0.link = ukaz.link; delete ukaz;
						if( !(ukaz0.link is null) ) { ukaz = ukaz0.link; }
						else { break; }
					}
				}
				ukaz0 = ukaz; ukaz = ukaz.link;
			}
			
 */			
			
		} 
	}
	// ______________________________________________________________
	bool isWordMono(string w) { //-> Есть целое слово в списке?
		size_t dlw, dln;
		bool rez; ubyte ind = getC0(w); un ukaz = harrow[ind];
		dlw = w.length;
		while(!(ukaz is null)) {
			dln = ukaz.str.length;
			if(dln == dlw) {
				if(ukaz.str == w) {
					rez = true; break;
				}
			}
			ukaz = ukaz.link;
		}
		return rez;
	}
	// ______________________________________________________________
	bool isWord(string w) { //-> Есть целое слово или производные в списке?
		size_t dlw, dln;
		bool rez; ubyte ind = getC0(w); un ukaz = harrow[ind];
		dlw = w.length;
		while(!(ukaz is null)) {
			dln = ukaz.str.length;
			if(dln >= dlw) {
				if(ukaz.str[0 .. dlw] == w) {
					rez = true; break;
				}
			}
			ukaz = ukaz.link;
		}
		return rez;
	}
	// ______________________________________________________________
	string[] getSubFromAll(string w) { //-> Выдать массив похожих слов из общего хранилища 
		string[] rez;
		string sh = toLower(w);
		foreach(el; masAllWords) {
			string wrd = toLower(el.str);
			if(indexOf(wrd, sh) > 0) {
				rez ~= el.str;
			}
		}
		return rez;
	}
	// ______________________________________________________________
	string[] getEq(string w) { //-> Выдать массив похожих слов из хранилища 
		string[] rez; size_t dlw, dln;
		if(w.length == 0) return rez;
		ubyte ind = getC0(w); un ukaz = harrow[ind];
		while(!(ukaz is null)) {
			dlw = w.length; dln = ukaz.str.length;
			if(dln >= dlw) { if(ukaz.str[0 .. dlw] == w) rez ~= ukaz.str; }
			ukaz = ukaz.link;
		}
		return rez;
	}
	// ______________________________________________________________
	void addLine(string line) { //-> Добавить строку в хранилище
		// import std.stdio;
		string clearLine = strip(line);
		if(clearLine == "") return;
		dchar[dchar] transTable = [
			'(':' ',
			')':' ',
			9:' ',
			'*':' ',
			';':' ',
			'.':' ',
			'[':' ',
			']':' ',
			',':' ',
			'"':' ',
			'!':' ',
			'/':' ',
			'=':' ',
			'\\':' ',
			':':' ',
			'@':' '
		];
		
		// if( indexOf(line, "//->") > 0 ) writeln(line);
		string zish = translate(clearLine, transTable);
		auto ms = split(zish, ' ');
		foreach(string el; ms) {
			string z = cast(string)strip(el);
			if(z.length > 2) {
				addWord(z);
			}
		}
	}
	// ______________________________________________________________
	void addFile(string nameFile) { //-> Добавить файл в хранилище
		File fileSrc = File(nameFile, "r");
		int ks;
		try {
			foreach(line; fileSrc.byLine()) {
				try {
					// Проверка на BOM
					if(ks++ == 0) if(line.length>2 && line[0]==239 && line[1]==187 && line[2]==191) line = line[3 .. $].dup;
					addLine(cast(string)strip(line));
				} catch {}
			}
		} catch {
			writeln("Error read file: ", nameFile);
			readln();
		}
	}
}
