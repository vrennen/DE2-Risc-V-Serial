projeto desenvolvido em iniciação científica de usar uma versão reduzida do risc-v para multiplicação de matrizes com envio e recebimento de informação a partir da porta serial

pelo sofrimento isso estar derretendo meus neuronios tentando consertar uma coisa e quebrando outra, vou colocar uma commit pra cada vez que eu conseguir 'arrumar' alguma coisa junto com info extra e o que preciso corrigir

problema atual: o assembly pre carregado aparentemente não esta funcionando como devia. Os registradores estão tendo valores incorretos ao executar manualmente ou de forma autonoma

explicacao dos asm novos carregados:

- matrixmul2.bin.old: codigo original feito por thiago e montado no RARS no codigo mulmatrizes.s. problema: os endereços de memória a ser carregado estão incorretos pois no RARS a sessão de dados começa em 0x10010000 enquanto na fpga começa em 0x0
- matrixmul2.bin.wtf: instruções de carregamento de endereços mudados de `auipc` para `lui` para ver se resolvia a contagem de endereços. problema: está surgindo o que parece ser uma instrução fantasma que faz o registrador *t0* receber 0x4 ao inves de 0x0. COMO QUE 0+0=4???
- matrixmul2.bin atual: removido as instruções `lui`, mantendo apenas as somas imediatas. as vezes funciona certo, as vezes nao, tentando investigar


Update 22/06/2025: FUNCIONA. FINALMENTE FUNCIONA. O PROBLEMA ESSE TEMPO TODO ERA SÓ O CLOCK MUITO RAPIDO. agora guardar aqui e nunca mais mexer sem salvar nessa violencia domestica em forma de descrição de hardware
