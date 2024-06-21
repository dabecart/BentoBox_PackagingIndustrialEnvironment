Master's thesis // TFM
================
*By Daniel Béjar Caballero, 2024.*

# Video presentation/Video de la presentación
[Link](https://youtu.be/DL5C0s1oAG4)

# Language/Lenguaje
- [Español](#descripcion-del-proyecto)
- [English](#projects-description)

# Descripción del proyecto
### Planta empaquetadora de Cajas Bentō mediante brazo robótico, PLC, interfaz HMI y comunicación TCP/IP 

Las cajas bentō son raciones de comida preparada para llevar bastante conocidas en Japón. Suelen traer raciones individuales de arroz, pescado, carne y guarniciones. 

En este proyecto se diseñará una empaquetadora industrial de cajas bento de cinco raciones. Dichas raciones llegarán a la empaquetadora desde cintas transportadoras individuales y de manera interrumpida. El PLC escogerá qué componente llevar al brazo robótico mediante una cinta general a la cual desembocan las otras cintas individuales. El brazo será el encargado del montaje de las cajas. Para ello, deberá recoger la caja base de un palé, las raciones de comida entregadas por la cinta general, y la tapadera de otro palé, en ese orden. Dispondrá de una mesa donde realizar el montaje de varias cajas a la vez. Debido a la existencia irregular de las raciones, el sistema podrá realizar varias cajas en paralelo. El sistema priorizará aquellas cajas que lleven más tiempo abiertas. Una vez terminada la caja, será transportada completa a una cinta que llevará a una estación de precintado (no desarrollada en este trabajo). 

El sistema dispondrá a su vez de una interfaz HMI. La comunicación full-duplex entre el brazo robótico y el PLC será realizado a través de TCP/IP mediante un protocolo de mensajes que será desarrollado específicamente para este proyecto.

El trabajo comienza con una descripción formal del sistema además de una explicación del protocolo utilizado para comunicar los diferentes componentes de este. 

Se detallará la programación del PLC “CPU 1515-2 PN” del fabricante Siemens mediante el IDE “TIA Portal v17”. Se describirán todas las variables de trabajo y los bloques funcionales del sistema utilizando el propio código como base para las explicaciones.

Sobre el brazo robótico “IRB 6700” de ABB, se hablará sobre su programación mediante el entorno visual y la programación en RAPID mediante el programa “RobotStudio”. Además, se describirán los componentes utilizados para el apartado visual del programa; es decir, para poder movilizar los objetos de la misma manera que lo haría el sistema en la vida real.

En otra sección, se describirá el diseño del dispositivo HMI o SCADA programado en el “TP1200 Comfort” de Siemens, también utilizando el entorno de “TIA Portal v17”. Se hablará sobre las diferentes funciones e integraciones realizadas para poder visualizar de manera rápida y efectiva el estado actual del sistema. Se describirán también las diferentes alarmas que pueden surgir en el funcionamiento del sistema.

También se añadirá una guía para poder comunicar ambos entornos de simulación (TIA Portal y RobotStudio) en un mismo ordenador, sin tener que hacer uso de componentes externos. Esta guía habilitará al lector de este documento para poder verificar el comportamiento descrito en este trabajo.

Finalmente, mediante el uso de capturas de pantalla de los simuladores, se pretenderá demostrar el funcionamiento del sistema completo; es decir, del funcionamiento simultáneo de PLC, robot y HMI.

# Project's description
### Box Packaging Plant Using Robotic Arm, PLC, HMI Interface, and TCP/IP Communication

Bentō boxes are portions of prepared food for takeout that are quite popular in Japan. They usually contain individual servings of rice, fish, meat, and side dishes.

In this project, an industrial packaging machine for five-portion bento boxes will be designed. These portions will arrive at the packaging machine from individual and intermittent conveyor belts. The PLC will choose which component to bring to the robotic arm via a main conveyor that collects the outputs of the individual belts. The arm will be responsible for assembling the boxes. To do this, it will need to pick up the base box from a pallet, the food portions delivered by the main conveyor, and the lid from another pallet, in that order. It will have a table where it can assemble several boxes simultaneously. Due to the irregular availability of portions, the system will be able to assemble several boxes in parallel. The system will prioritize boxes that have been open the longest. Once a box is completed, it will be transported to a conveyor belt that will carry it to a sealing station (not developed in this work).

The system will also include an HMI interface. Full-duplex communication between the robotic arm and the PLC will be achieved through TCP/IP using a message protocol specifically developed for this project.

The work begins with a formal description of the system along with an explanation of the protocol used to communicate its different components.

The programming of the “CPU 1515-2 PN” PLC from Siemens will be detailed using the “TIA Portal v17” IDE. All working variables and functional blocks of the system will be described using the code itself as the basis for the explanations.

Regarding the “IRB 6700” robotic arm from ABB, its programming will be discussed using the visual environment and RAPID programming through the “RobotStudio” software. Additionally, the components used for the visual aspect of the program will be described; that is, to move objects in the same way as the system would in real life.

In another section, the design of the HMI or SCADA device programmed on Siemens’ “TP1200 Comfort” will be described, also using the “TIA Portal v17” environment. The different functions and integrations made to quickly and effectively visualize the current state of the system will be discussed. The various alarms that may arise during the system's operation will also be described.

A guide will also be added to enable communication between both simulation environments (TIA Portal and RobotStudio) on the same computer, without the need for external components. This guide will enable the reader of this document to verify the behavior described in this work.

Finally, through the use of screenshots from the simulators, the functioning of the complete system will be demonstrated; that is, the simultaneous operation of the PLC, robot, and HMI.