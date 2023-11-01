function Adeus () { 
    var nome
    document.getElementById('resposta').innerHTML = ' <b> Nova mensagem via javascript </b>'
    nome = window.prompt('Digite seu nome:')
    
    document.getElementById('nome').innerHTML = ' <b> o nome digitado é </b>' + nome
    
}

function alterFundo()
{
    var el = document.getElementById('Container')
    if (el.style.backgroundColor == 'white')
    {
        el.style.cssText = 'background-color: black; ' + 
                           'color: white';
    }
    else {
        el.style.cssText = 'background-color:white ; ' + 
        'color: black';
    }

}