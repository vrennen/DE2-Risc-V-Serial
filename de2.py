import serial
import time
import sys

if len(sys.argv) != 3:
    print(f"Uso: {sys.argv[0]} <porta> <baud>")
    exit()

lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam posuere eros in metus molestie venenatis. Aliquam commodo augue a facilisis posuere. Suspendisse vitae ipsum sollicitudin, ornare arcu vel, viverra magna. Fusce eu justo lectus. Proin volutpat."

baudrate = int(sys.argv[2])
# inicializa a porta serial para comunicacao 
# para linux, a porta sera /dev/ttyUSBx enquanto para windows, a porta sera COMx
# sendo x um numero que pode ser visto, respectivamente, rodando `ls /dev/ttyUSB*`, ou no Gerenciador de Dispositivos na secao "Portas (COM e LPT)" 
placa = serial.Serial(sys.argv[1], baudrate)

# tempo inicial
start = time.time()
placa.write(lorem.encode())
# o caractere 0x00 sinaliza a placa que a transmissao acabou e deve enviar toda a string de volta
placa.write(b'\x00')

# tempo apos enviar os dados e antes de receber de volta
envioStamp = time.time()
tempoEnvio = enviostamp - start

rec = placa.read(256)
tempoRecebimento = time.time() - enviostamp

# confirmar se o dado recebido eh exatamente igual ao enviado
print(rec)
print(rec == lorem.encode())

print("tempo total: ", time.time() - start)
print("tempo envio: ", tempoEnvio)
print("tempo receb: ", tempoRecebimento)
