##################################################################
# TCPTunel es un nexo de conexión entre las interfaces de red del 
# PLC y la del robot. Es necesario puesto que el PLC no permite 
# crear una IP nueva dentro de la red (que correspondería al 
# robot).
##################################################################

##################################################################
# LIBRERIAS
##################################################################
import socket
import threading
import time

##################################################################
# VARIABLES GLOBALES Y CONSTANTES
##################################################################
stopProgram = False

# IP y puerto de TIA Portal
tiaHost = '192.168.0.130'
tiaPort = 2000
# IP y puerto de RobotStudio
abbHost = "127.0.0.1" # localhost
abbPort = 9876

##################################################################
# FUNCIONES
##################################################################

# Hilo de conexión TIA --> ABB
def tiaToABB(tia_conn, tia_addr, abbSocket):
  global stopProgram

  while not stopProgram:
    try:
      tia_conn.settimeout(1.0)
      recv = tia_conn.recv(1024)
      if recv:
        print(f"TIA => ABB ({len(recv)}): {recv}")
        abbSocket.send(recv)
    except socket.timeout:
      pass
    except ConnectionResetError:
      print("TIA disconnected!")
      stopProgram = True

# Hilo de conexión ABB --> TIA
def abbToTia(tia_conn, tia_addr, abbSocket):
  global stopProgram

  while not stopProgram:
    try:
      abbSocket.settimeout(1.0)
      recv = abbSocket.recv(1024)
      if recv:
        print(f"ABB => TIA ({len(recv)}): {recv}")
        tia_conn.sendall(recv)
    except socket.timeout:
      pass
    except ConnectionResetError:
      print("ABB disconnected!")
      stopProgram = True

# Main
try:
  tiaSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  tiaSocket.bind((tiaHost, tiaPort))
  print(f"TIA PORTAL conectado en {tiaHost}:{tiaPort}")
  tiaSocket.listen()
  tia_conn, tia_addr = tiaSocket.accept()

  abbSocket = socket.socket()
  abbSocket.connect((abbHost, abbPort))
  print(f"ROBOT STUDIO conectado en {abbHost}:{abbPort}")

  tiaToABBThread = threading.Thread(target=tiaToABB, args=(tia_conn, tia_addr, abbSocket))
  abbToTiaThread = threading.Thread(target=abbToTia, args=(tia_conn, tia_addr, abbSocket))

  tiaToABBThread.start()
  abbToTiaThread.start()

  while tiaToABBThread.is_alive() and abbToTiaThread.is_alive():
      time.sleep(0.1)

except KeyboardInterrupt:
  stopProgram = True