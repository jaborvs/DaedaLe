module PuzzleScript::SalixTest

import salix::HTML;
import salix::Core;
import salix::App;
import salix::Index;


alias Model = int;

Model init() = 0;

data Msg = inc() | dec();

Model update(Msg msg, Model model) {
    switch (msg) {
    case inc(): model += 1;
    case dec(): model -= 1;
    }
    return model;
}

void view(Model m) {
    div(() {
    h2("My first counter app in Rascal");
    button(onClick(inc()), "+");
    div(m.count);
    button(onClick(dec()), "-");
    });
}

SalixApp[Model] counterApp(str appId = "counterApp") = makeApp(appId, init, view, update);

App[Model] counterWebApp() 
      = webApp(counterApp(), |project://automatedpuzzlescript/src/PuzzleScript/Interface/index.html|, |project://automatedpuzzlescript/src|);