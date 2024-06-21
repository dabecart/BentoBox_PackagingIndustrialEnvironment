MODULE Module1
! Declaracion de los targets.
CONST robtarget Targ_CajaE:=[[-500,1500,200],[0,0,1,0],[1,0,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
CONST robtarget Targ_CajaF:=[[400,1500,200],[0,0,1,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
CONST robtarget Targ_CintaEmpaq:=[[-0.000065567,-1500.000031808,200.000065078],[0,0,1,-0.000000008],[-2,0,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
CONST robtarget Targ_CintaLlegada:=[[-1500.000032056,1000.000001355,200.000069515],[-0.000000007,0,1,0.000000004],[1,0,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
CONST robtarget Targ_Mesa:=[[999.999977515,1500.00004795,215.000069515],[0.000000008,0.707106781,0.707106781,0.000000002],[0,-1,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
CONST robtarget Targ_Home:=[[900,0,750],[0,0.707106781,0.707106781,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];

! Numero maximo de posiciones dentro de la mesa.
CONST num maximoNumMesas := 12;
! Numero maximo de materiales para los que el robot ha sido programado.
CONST num maximoNumMateriales := 5;

VAR socketdev serverSocket;
VAR socketdev clientSocket;
VAR bool servidorConectado := FALSE;
VAR string inputData;

! Almacena el numero de componentes (sin contar base y tapa) que maneja el robot.
VAR num numeroMateriales := maximoNumMateriales;
! Almacena el numero maximo de mesas que esta manejando el sistema en ese momento.
VAR num numeroMesas := maximoNumMesas;
! TRUE si hay algun material pegado a las ventosas. Variable necesaria por si falla la ventosa.
VAR bool transportandoMaterial := FALSE;

! Interrupcion para gestionar la deteccion de piezas.
VAR intnum int_DISensorPieza;

!**************************************************************************************************
! main() es la funcion de comienzo del programa. Si termina, se vuelve a ejecutar desde el 
! comienzo.
!**************************************************************************************************
PROC main()
    ! Enlazar interrupcion con su funcion de interrupcion.
    CONNECT int_DISensorPieza WITH IntSensorPiezas;
    ! Disparar interrupcion unicamente cuando falle el sensor de piezas (pase de uno a cero la 
    ! entrada DI_SensorPieza).
    ISignalDI DI_SensorPieza, 0, int_DISensorPieza;
    
    ! Esperar conexion entrante del PLC
    ConectarTCP;    
    ! Mientras este conectado, realizar las peticiones del PLC.
    WHILE servidorConectado DO
        ProcesarMensajesTCP;
    ENDWHILE
ENDPROC

!**************************************************************************************************
! IntSensorPiezas es la funcion que se ejecuta cuando el sensor da un fallo mientras se esta 
! transportando material.
!**************************************************************************************************
TRAP IntSensorPiezas
    IF transportandoMaterial THEN
        EscribirTCP "1?ACT";
        StopMove;
    ENDIF
ENDTRAP

!**************************************************************************************************
! ProcesarMensajesTCP() recibe los mensajes por TCP y realiza los movimientos u operaciones que 
! el PLC instruya al robot.
!**************************************************************************************************
PROC ProcesarMensajesTCP()
    VAR bool msgOK;
    VAR num inputID;
    VAR num matDestino;
    VAR num mesaDestino;
    VAR bool mensajeRecibido;

    ! Recepcion de datos desde el TCP (bloquea el programa durante 10 segundos). Si no se recibe
    ! nada envia un mensaje para tratar de conectarse.
    mensajeRecibido := LeerTCP(10);
    IF NOT mensajeRecibido THEN
        ! Trata de reconectar.
        SolicitarConfiguracion;
        RETURN;
    ENDIF
    
    ! Convertir el numero inicial del mensaje a numero.
    msgOK := StrToVal(StrPart(inputData,1,1), inputID);
    IF NOT msgOK THEN
        ! Mandar mensaje de error de transmision.
        ErrorRX "ID";
        RETURN;
    ENDIF
    
    ! Coger material.
    IF inputID = 3 THEN
        IF StrLen(inputData) < 8 THEN
            ErrorRX "LEN";
            RETURN;
        ENDIF
        
        ! Obtener la ID del material que se desea coger.
        matDestino := ConvertirStringMaterial(StrPart(inputData,2,4));
        IF matDestino < 0  OR matDestino >= (numeroMateriales+2) THEN
            ! Error al parsear la ID del material.
            ErrorRX "MAT";
            RETURN;
        ENDIF
        
        ! Activar senales digitales para que ReponedorPiezas genere las piezas 
        ! correspondientes.
        IF matDestino = numeroMateriales THEN
            PulseDO \High,\PLength:=0.5, DO_PiezaE;
        ELSEIF matDestino = numeroMateriales+1 THEN
            PulseDO \High,\PLength:=0.5, DO_PiezaF;
        ELSEIF matDestino = 0 THEN
            PulseDO \High,\PLength:=0.5, DO_PiezaA;
        ELSEIF matDestino = 1 THEN
            PulseDO \High,\PLength:=0.5, DO_PiezaB;
        ELSEIF matDestino = 2 THEN
            PulseDO \High,\PLength:=0.5, DO_PiezaC;
        ELSEIF matDestino = 3 THEN
            PulseDO \High,\PLength:=0.5, DO_PiezaD;
        ELSEIF matDestino = 4 THEN
            PulseDO \High,\PLength:=0.5, DO_PiezaD;
        ELSE
            ! Mandar mensaje de error fatal, no deberia ser posible entrar aqui.
            ErrorRX "FATAL";
            RETURN;
        ENDIF
        
        ! Obtener la ID de la mesa destino de la pieza.
        mesaDestino := StrToByte(StrPart(inputData,7,2)\Hex);
        IF mesaDestino >= maximoNumMesas THEN
            ErrorRX "MESA";
            RETURN;
        ENDIF
        
        ! Enviar el ACK.
        EscribirTCP "0ACK3";
        
        ! Comprobacion rapida por si hay un mensaje para detener el programa.
        mensajeRecibido := LeerTCP(0.5);
        IF mensajeRecibido THEN
            ! Convertir el numero inicial del mensaje a numero.
            msgOK := StrToVal(StrPart(inputData,1,1), inputID);
            IF NOT msgOK THEN
                ! Mandar mensaje de error de transmision.
                ErrorRX "ID";
                RETURN;
            ENDIF
            ComprobarAsincronas(inputID);
        ENDIF
        
        ! Algoritmo de posicionamiento de objetos en mesas.
        ColocarEnMesa matDestino, mesaDestino;
        
        ! Una vez colocado el objeto, manda senal de MaterialColocado.
        EscribirTCP "3MAT_COL";

    ! Coloca una caja completa en la cinta de empaquetado.
    ELSEIF inputID = 4 THEN
        IF StrLen(inputData) < 4 THEN
            ErrorRX "LEN";
            RETURN;
        ENDIF
        
        ! Obtener la ID de la posicion donde se encuentra la caja que se desea colocar
        ! en la cinta general.
        mesaDestino := StrToByte(StrPart(inputData,3,2)\Hex);
        IF mesaDestino > maximoNumMesas THEN
            ErrorRX "MESA";
            RETURN;
        ENDIF
        
        ! Enviar el ACK.
        EscribirTCP "0ACK4";
        
        ! Comprobacion rapida por si hay un mensaje para detener el programa.
        mensajeRecibido := LeerTCP(0.5);
        IF mensajeRecibido THEN
            ! Convertir el numero inicial del mensaje a numero.
            msgOK := StrToVal(StrPart(inputData,1,1), inputID);
            IF NOT msgOK THEN
                ! Mandar mensaje de error de transmision.
                ErrorRX "ID";
                RETURN;
            ENDIF
            ComprobarAsincronas(inputID);
        ENDIF
        
        ! Algoritmo de posicionamiento de cajas completas en la cinta de empaquetado.
        ColocarCajaCompleta mesaDestino;
        
        ! Una vez colocada la caja, manda senal de MaterialColocado.
        EscribirTCP "3MAT_COL";

    ! Ir a HOME y otras senales.
    ELSE
        ComprobarAsincronas(inputID);
    ENDIF
ENDPROC

!**************************************************************************************************
! ColocarEnMesa(num mat, num mesa) recibe la ID del material y de la mesa donde se desea colocar 
! dicho material y genera las instrucciones de movimiento del brazo del robot.
!**************************************************************************************************
PROC ColocarEnMesa(num mat, num mesa)
    VAR num x;
    VAR num y;
    VAR num xPos;
    VAR num yPos;
    VAR robtarget posicionFinal;
    
    ! Obtener la posicion X,Y dentro de la mesa. La esquina superior izquierda desde el punto 
    ! de vista de la cinta de empaquetado es el 0,0. El numero de la mesa se puede recalcular 
    ! como X*6+Y.
    x := mesa DIV 6;
    y := mesa MOD 6;
    
    ! Obtener las esquinas de la posicion de la mesa que se indica. A partir de estas se 
    ! desplazaran las coordenadas donde se encuentran individualmente las piezas con respecto la 
    ! bandeja.
    xPos := 200 + x*400;
    yPos := 80 + y*500;
    
    ! Punto final donde se colocara el componente. En esta linea es la posicion de la esquina
    ! superior izquierda de la mesa que se esta pasando a esta funcion en referencia al mundo.
    posicionFinal := Offs(Targ_Mesa, xPos, -yPos, 0);
    
    ! Dependiendo del material, la posicion donde se colocara variara. Esto ira en referencia
    ! a la posicion calculada anteriormente.
    IF mat = numeroMateriales THEN
        ! Base de la caja.
        posicionFinal := Offs(posicionFinal, 115,-170,40);
    ELSEIF mat = numeroMateriales+1 THEN
        ! Tapadera de la caja.
        posicionFinal := Offs(posicionFinal, 115,-170,93);
    ELSEIF mat = 0 THEN
        posicionFinal := Offs(posicionFinal, 75,-225,85);
    ELSEIF mat = 1 THEN
        posicionFinal := Offs(posicionFinal, 177,-283,85);
    ELSEIF mat = 2 THEN
        posicionFinal := Offs(posicionFinal, 177,-167,85);
    ELSEIF mat = 3 THEN
        posicionFinal := Offs(posicionFinal, 60,-60,85);
    ELSEIF mat = 4 THEN
        posicionFinal := Offs(posicionFinal, 170,-60,85);
    ENDIF
    
    ! Seleccion de la posicion donde se recogera el material.
    IF mat = numeroMateriales THEN
        ! Posicion de recogida de la caja.
        MoveJ Offs(Targ_CajaE,0,0,400),v5000,z20,GarraVentosas\WObj:=wobj0;
        MoveL Targ_CajaE,v500,fine,GarraVentosas\WObj:=wobj0;
        PulseDO \High,\PLength:=0.5, DO_Vacio;
        transportandoMaterial := TRUE;
        MoveL Offs(Targ_CajaE,0,0,400),v1000,z20,GarraVentosas\WObj:=wobj0;
    ELSEIF mat = numeroMateriales+1 THEN 
        ! Posicion de recogida de la tapa.
        MoveJ Offs(Targ_CajaF,0,0,400),v5000,z20,GarraVentosas\WObj:=wobj0;
        MoveL Targ_CajaF,v500,fine,GarraVentosas\WObj:=wobj0;
        PulseDO \High,\PLength:=0.5, DO_Vacio;
        transportandoMaterial := TRUE;
        MoveL Offs(Targ_CajaF,0,0,400),v1000,z20,GarraVentosas\WObj:=wobj0;
    ELSE
        ! Componentes de la cinta general.
        MoveJ Offs(Targ_CintaLlegada,0,0,400),v5000,z20,GarraVentosas\WObj:=wobj0;
        MoveL Targ_CintaLlegada,v500,fine,GarraVentosas\WObj:=wobj0;
        PulseDO \High,\PLength:=0.5, DO_Vacio;
        transportandoMaterial := TRUE;
        MoveL Offs(Targ_CintaLlegada,0,0,400),v1000,z20,GarraVentosas\WObj:=wobj0;
    ENDIF
    
    ! Mandar senal de material recogido.
    EscribirTCP "2MAT_REC";
    
    ! Dejar el material en la posicion final.
    MoveJ Offs(posicionFinal,0,0,400),v5000,z20,GarraVentosas\WObj:=wobj0;
    MoveL posicionFinal,v500,fine,GarraVentosas\WObj:=wobj0;
    PulseDO \High,\PLength:=0.5, DO_Soplar;
    transportandoMaterial := FALSE;
    MoveL Offs(posicionFinal,0,0,400),v1000,fine,GarraVentosas\WObj:=wobj0;
ENDPROC

!**************************************************************************************************
! ColocarCajaCompleta(num mat) coloca una caja completa en la cinta de empaquetado.
!**************************************************************************************************
PROC ColocarCajaCompleta(num mesa)
    VAR num x;
    VAR num y;
    VAR num xPos;
    VAR num yPos;
    VAR robtarget posicionFinal;

    ! Obtener la posicion X,Y dentro de la mesa. La esquina superior izquierda desde el punto 
    ! de vista de la cinta de empaquetado es el 0,0. El numero de la mesa se puede recalcular 
    ! como X*6+Y.
    x := mesa DIV 6;
    y := mesa MOD 6;
    
    ! Anadir la posicion del centro de la caja (115, 170); es decir, la mitad de las 
    ! dimensiones.
    xPos := 200 + x*400 + 115;
    yPos := 80 + y*500 + 170;
    
    ! Posicion del centro de la caja en la mesa.
    posicionFinal := Offs(Targ_Mesa, xPos, -yPos, 93);
    
    MoveJ Offs(posicionFinal,0,0,400),v5000,z20,GarraVentosas\WObj:=wobj0;
    MoveL posicionFinal,v500,fine,GarraVentosas\WObj:=wobj0;
    PulseDO \High,\PLength:=0.5, DO_VacioCaja;
    transportandoMaterial := TRUE;
    MoveL Offs(posicionFinal,0,0,400),v1000,z20,GarraVentosas\WObj:=wobj0;
    
    ! Dejar el material en la cinta de empaquetado.
    MoveJ Offs(Targ_CintaEmpaq,0,0,400),v5000,z20,GarraVentosas\WObj:=wobj0;
    MoveL Targ_CintaEmpaq,v500,fine,GarraVentosas\WObj:=wobj0;
    transportandoMaterial := FALSE;
    PulseDO \High,\PLength:=0.5, DO_SoplarCaja;
    MoveL Offs(Targ_CintaEmpaq,0,0,400),v1000,fine,GarraVentosas\WObj:=wobj0;
ENDPROC

!**************************************************************************************************
! ConectarTCP() esta funcion realiza la conexion mediante TCP al socket del cliente. Una vez 
! realizada la conexion, manda un mensaje con su configuracion inicial al PLC y espera una 
! respuesta para confirmar que esta correctamente conectado.
!**************************************************************************************************
PROC ConectarTCP()    
    ! Inicializacion de los sockets.
    SocketCreate serverSocket;
    SocketBind serverSocket, "127.0.0.1", 9876;
    SocketListen serverSocket;
    SocketAccept serverSocket, clientSocket,\Time:=WAIT_MAX;
    SolicitarConfiguracion;
ENDPROC

!**************************************************************************************************
! SolicitarConfiguracion() manda al PLC un mensaje con la configuracion actual del robot. Espera 
! que el PLC le devuelva la configuracion que esta utilizando y la adopta si es valida.
!**************************************************************************************************
PROC SolicitarConfiguracion()
    VAR bool msgOK;
    VAR num inputID;

SolicitarConfig:
    ! Mandar mensaje de conexion completada junto con el numero m?ximo de mesas y materiales
    ! permitidos.
    EscribirTCP "405M0C";
    ! Espera la respuesta del sistema con la configuracion.
    msgOK := LeerTCP(5);
    IF NOT msgOK THEN
        GOTO SolicitarConfig;        
    ENDIF
    
    ! Comprobar la longitud de la cadena.
    IF StrLen(inputData) < 6 THEN
        ErrorRX("LEN");
        GOTO SolicitarConfig;
    ENDIF
    
    ! Comprobar que la ID es la de Parametros.
    msgOK := StrToVal(StrPart(inputData,1,1), inputID);
    IF inputID <> 5 THEN
        GOTO SolicitarConfig;
    ENDIF
    
    ! Obtener el numero maximo de materiales por bandeja.
    numeroMateriales := StrToByte(StrPart(inputData,2,2)\Hex);
    IF numeroMateriales > maximoNumMateriales THEN
        ErrorRX("CONF_MAT");
        GOTO SolicitarConfig;
    ENDIF
    
    ! Obtener el numero de mesas que puede haber.
    numeroMesas := StrToByte(StrPart(inputData,5,2)\Hex);
    IF numeroMesas > maximoNumMesas THEN
        ErrorRX("CONF_MESA");
        GOTO SolicitarConfig;
    ENDIF
    
    ! Enviar ACK. La conexion con el PLC ya ha sido establecida.
    EscribirTCP "0ACK5";
    servidorConectado := TRUE;
ENDPROC

!**************************************************************************************************
! ErrorRX(string errMsg) es una funcion que envia al PLC un mensaje de error tras la recepcion de 
! un mensaje que el PLC ha mandado.
!**************************************************************************************************
PROC ErrorRX(string errMsg)
    EscribirTCP "1?"+errMsg;
    PulseDO \High,\PLength:=1, DO_ErrorRX;
ENDPROC

!**************************************************************************************************
! Reconectar() cierra los sockets y vuelve a intentar realizar una conexion con el PLC.
!**************************************************************************************************
PROC Reconectar()
    SocketClose serverSocket;
    SocketClose clientSocket;
    servidorConectado := FALSE;
    ConectarTCP;
ENDPROC

!**************************************************************************************************
! bool LeerTCP(num time) sirve para recibir un mensaje del PLC mediante TCP. Puede ser especificado
! un tiempo limite de espera, tras el cual se lanza una excepcion que es recogida en la seccion de
! ERROR. Devuelve true cuando el mensaje recibido es valido y false si no se ha recibido ningun 
! mensaje antes de que acabe el tiempo de espera. Si el socket se desconecta intenta reconectarse 
! y vuelve a leer el TCP.
!**************************************************************************************************
FUNC bool LeerTCP(num time)
    ! Comprobacion rapida por si hay un mensaje para detener el programa.
    SocketReceive clientSocket, \Str:=inputData, \Time:=time;
    RETURN TRUE;
ERROR
    IF ERRNO=ERR_SOCK_TIMEOUT THEN
        RETURN FALSE;
    ELSEIF ERRNO=ERR_SOCK_CLOSED THEN
        Reconectar;
        RETRY;
    ELSE
        ! Error desconocido, el sistema se apagara.
        Stop;
    ENDIF
ENDFUNC

!**************************************************************************************************
! EscribirTCP(string data) escribe por TCP mensajes hacia el PC. Si el socket se desconectara 
! trata de reconectarse y vuelve a lanzar el mensaje.
!**************************************************************************************************
PROC EscribirTCP(string data)
    SocketSend clientSocket \Str:=data;
ERROR
    IF ERRNO=ERR_SOCK_CLOSED THEN
        Reconectar;
        RETRY;
    ELSE
        ! Error desconocido, el sistema se apagara.
        Stop;
    ENDIF
ENDPROC

!**************************************************************************************************
! ComprobarAsincronas(num inputID) procesa aquellos mensajes que no estan relacionados con el 
! funcionamiento normal del sistema; por ejemplo, las instrucciones enviadas por operarios desde
! el HMI.
!**************************************************************************************************
PROC ComprobarAsincronas(num inputID)
    VAR bool msgOK;
    
    ! Estado del sistema. Mandar simplemente un ack.
    IF inputID = 2 THEN
        EscribirTCP "0ACK2";
    ! Parametros de configuracion.
    ELSEIF inputID = 5 THEN
        ! Comprobar la longitud de la cadena.
        IF StrLen(inputData) < 6 THEN
            ErrorRX("LEN");
            RETURN;
        ENDIF
        
        ! Comprobar que la ID es la de Parametros.
        msgOK := StrToVal(StrPart(inputData,1,1), inputID);
        IF inputID <> 5 THEN
            RETURN;
        ENDIF
        
        ! Comprobar que el numero de materiales por bandeja no supera el maximo.
        numeroMateriales := StrToByte(StrPart(inputData,2,2)\Hex);
        IF numeroMateriales > maximoNumMateriales THEN
            ErrorRX("NUM_MAT");
            RETURN;
        ENDIF
        
        ! Comprobar que el numero de mesas no supera el maximo.
        numeroMesas := StrToByte(StrPart(inputData,5,2)\Hex);
        IF numeroMesas > maximoNumMesas THEN
            ErrorRX("NUM_MES");
            RETURN;
        ENDIF
        
        EscribirTCP "0ACK5";
        servidorConectado := TRUE;
        
    ! Ir a HOME
    ELSEIF inputID = 6 THEN    
        ! Enviar el ACK.
        EscribirTCP "0ACK6";
        
        MoveJ Targ_Home,v500,fine,GarraVentosas\WObj:=wobj0;
        
    ! Apagar la maquina
    ELSEIF inputID = 7 THEN
        ! Enviar el ACK.
        EscribirTCP "0ACK7";
        ! Ir a home y apagar.
        MoveJ Targ_Home,v500,fine,GarraVentosas\WObj:=wobj0;
        Stop;
    ENDIF    
ENDPROC

!**************************************************************************************************
! num ConvertirStringMaterial(string strMat) recibe un string con el identificador del material y 
! lo convierte a un numero que reconoce el robot. En caso de haber algun error, devuelve -1.
!**************************************************************************************************
FUNC num ConvertirStringMaterial(string strMat)
    VAR num numMatEntrada;
    VAR num numMat := 0;
    numMatEntrada := BitLsh(StrToByte(StrPart(strMat,1,2)\Hex),8) + 
                     StrToByte(StrPart(strMat,3,2)\Hex);
    WHILE BitAnd(numMatEntrada, 1) = 0 DO
        numMatEntrada := BitRsh(numMatEntrada, 1);
        numMat := numMat + 1;
    ENDWHILE
    
    IF BitRsh(numMatEntrada, 1) <> 0 THEN
        RETURN -1;
    ENDIF
    RETURN numMat;
ENDFUNC

!**************************************************************************************************
! Funcion no utilizada. Sirve para poder transferir puntos desde la ventanda de posicion inicial 
! a RAPID.
!**************************************************************************************************
PROC Path_10()
    MoveL Targ_CajaE,v500,z20,GarraVentosas\WObj:=wobj0;
    MoveL Targ_CajaF,v500,z20,GarraVentosas\WObj:=wobj0;
    MoveL Targ_CintaEmpaq,v500,z20,GarraVentosas\WObj:=wobj0;
    MoveL Targ_CintaLlegada,v500,z20,GarraVentosas\WObj:=wobj0;
    MoveL Targ_Home,v500,z20,GarraVentosas\WObj:=wobj0;
    MoveL Targ_Mesa,v500,z20,GarraVentosas\WObj:=wobj0;
ENDPROC
    
ENDMODULE