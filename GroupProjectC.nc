#include "Timer.h"
#include "printf.h"
#include "GroupProject.h"
 
/** 
 * This is the skeleton app for the group project of the Low-Power Systems Design course.
 * 
 * A data generation component (DataGeneratorC) signals data events at a fixed interval. The data rate 
 * can be configured at compile by defining the constant DATARATE, e.g. "-DDATARATE=10" for 10 packets
 * per second.
 * The skeleton app broadcasts one packet for every generated event. On receive, every node forwards
 * packet that it has not seen yet. This forwarding concept, called flooding, propagates the packets in
 * the whole network. A sink node prints out the received packets.
 **/

  typedef nx_struct combined_msg {
    nx_am_addr_t source;
    nx_uint8_t seq_no;
    nx_uint8_t size;
    nx_uint16_t data[10];  
  } combined_msg_t;
 
module GroupProjectC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface Timer<TMilli> as MilliTimer2;
    interface SplitControl as AMControl;
    interface Packet;
    interface CC2420Config;
    interface Notify<group_project_msg_t>;
    interface Cache<cache_entry_t>;
    interface Pool<message_t>;
    interface Queue<message_t *>;
    interface AMSend as SerialSend;
#ifndef COOJA
    interface StdControl as ClockCalibControl;
#endif
    interface Random;
    
  }
}
implementation {

#ifdef debug_printf
#undef dbg

#define dbg(component, fmt, ...) do {\
  printf(fmt, ##__VA_ARGS__);\
  } while(0);
#endif
 

/*
#define dbg(component, fmt, ...) do {\
  } while(0);
#endif
#endif*/

  bool locked;
  bool radioOn;
  bool startedRadioAlready;
  uint8_t seq_no = 0;

  bool DataHasStartedArriving=FALSE;
  
  // function prototypes
  error_t enqueue(message_t * m);
  message_t * forward(message_t * fm);
  void message_to_cache_entry(message_t *m, cache_entry_t * c);
  void senddone(message_t* bufPtr, error_t error);
  void startSlow3sTimer();
  void startCustomTimer(uint16_t delay);
  void startRandomForwardTimer();
  void startImmediateTimer();
  void startRadioTurnOnTimer();
  void startPeriodicAt(uint16_t t0_start, uint16_t dt_delay);
  
  task void sendTask();

  
  enum {
    FORWARD_DELAY_MS = 100, // max wait time between two forwarded packets
  };
  
  event void Boot.booted() 
  {
    if(TOS_NODE_ID == 1   )
    {
     call AMControl.start();
     //not for node 3 anymore do it when data starts coming
    }
    
    if(TOS_NODE_ID == 3 || TOS_NODE_ID ==6 || TOS_NODE_ID == 16|| TOS_NODE_ID == 22|| TOS_NODE_ID == 28|| TOS_NODE_ID == 31|| TOS_NODE_ID == 32 )
    {
      dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
        call CC2420Config.setChannel(20);
	call CC2420Config.sync(); 
      dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
    }
//     if(TOS_NODE_ID == 31 || TOS_NODE_ID ==32 || TOS_NODE_ID == 3)
//     {
//       dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
//         call CC2420Config.setChannel(19);
// 	call CC2420Config.sync(); 
//       dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
//     }
    
#ifndef COOJA
    call ClockCalibControl.start();
#endif
//     	      dbg("GroupProjectC", "Setting initial timers \n");

    // start slow timer on  boot    startPeriodicAt(uint16_t t0_start, uint16_t dt_delay) 
	switch (TOS_NODE_ID)
	    {
	      case 1: //do shit and 100% duty cycling
	      // FlockLab nodes 1, 2, 3, 4, 6, 8, 15, 16, 22, 28, 31, 32, and 33
  		startPeriodicAt(5,100);
		 
	      break;
	      

	      
	      
	      //DIRECTLY
	      case 2: // forwards and receives packets. 1st layer of burst.
		    // Can receive from nodes 1, 4, 8, 15, and 33.
 		startPeriodicAt(0,250);
		 
	      break;
	      
	      
	      //FWDING NODE
	      case 3: //forwards and receives packets. 2nd layer of burst.
	      // Can receive from nodes 33, 32, 31, 6, 8, 15
 		startPeriodicAt(125,250);
		  
	      break;
	      
	      //DIRECTLY
	      case 4: //forwards and receives packets. 1st layer of burst.
	      // Can receive from nodes 1, 2, 8, 15, and 33.
 		startPeriodicAt(25,250);
		 
	      break;
	     
	      
	      //VIA NODE 3
	      case 6: //forwards and receives packets. 3rd layer of burst.
	      // Can receive from nodes 3, 33, 28, 22, 16, 
		startPeriodicAt(0, 250);
		 
	      break;
	      
	      //DIRECTLY
	      case 8: //forwards and receives packets. 1st layer of burst.
	      // Can receive from nodes 1, 2, 4, 15, 33, 3 
 		startPeriodicAt(50,250);
		 
	      break;
	      //DIRECTLY
	      case 15: //forwards and receives packets. 1st layer of burst.
	      // Can receive from nodes 1, 2, 4, 8, 33, 3 
 		startPeriodicAt(75,250);
		 
	      break;

	      
	      





	      //VIA NODE 3
	      case 16: //forwards and receives packets. 3rd layer of burst.
	      // Can receive from nodes 6, 22, 28, 3
		startPeriodicAt(21, 250);
		 
	      break;
	      //VIA NODE 3
	      case 22: //forwards and receives packets. 3rd layer of burst.
	      // Can receive from nodes 6, 16, 28, 3
		startPeriodicAt(42, 250);
		 
	      break;	
	      //VIA NODE 3
	      case 28: //forwards and receives packets. 3rd layer of burst.
	      // Can receive from nodes 6, 16, 22, 3, 33
 		startPeriodicAt(62, 250);
		 
	      break;
	      //VIA NODE 3
	      case 31: //forwards and receives packets. 2nd layer of burst.
	      // Can receive from nodes 32, 33, 3, 28
 		startPeriodicAt(83, 250);
		 
	      break;
	      //VIA NODE 3
	      case 32: //forwards and receives packets. 2nd layer of burst.
	      // Can receive from nodes 31, 3, 33, 15
 		startPeriodicAt(104, 250);
		 
	      break;

	      
   
	      //DIRECTLY
	      case 33: //forwards and receives packets. 2nd layer of burst.
	      // Can receive from nodes 8, 15, 2, 3, 32, 31
 		startPeriodicAt(100,250);
		 
	      break;
	      
	      
	      



	      default:
	      
	    }
	    
 
      
    
    
  }
  
 
  event void CC2420Config.syncDone( error_t error ) 
  {
         dbg("GroupProjectC", "Radio syncDone .\n");
  }
  
  
  
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      radioOn=TRUE;
//      call Leds.led1On();
//      dbg("GroupProjectC", "Radio sucessfully booted, Radio is on, datarate is %u.\n", datarate);
    }
    else {
      call AMControl.start();
    }
  }
  
  event void AMControl.stopDone(error_t err) {
    // do nothing
    
  }
  
  
 
task void sendTask() {
  error_t ret;
  
//    dbg("GroupProjectC", "\nsend Task fired.\n");

  
  if (radioOn == FALSE) // try again later
  {
      //post sendTask();  // we now have a timer dont do it anymore
        dbg("GroupProjectC", "ERROR radio is off during send task.\n");
      return;
  }
  
  if (!call Queue.empty()) 
    {
      switch (TOS_NODE_ID)
      {
	case 1: //do shit and 100% duty cycling
	 // FlockLab nodes 1, 2, 3, 4, 6, 8, 15, 16, 22, 28, 31, 32, and 33
	    //dbg("GroupProjectC", "serial sending.\n");
	ret = call SerialSend.send(AM_BROADCAST_ADDR, call Queue.head(), sizeof(group_project_msg_t));
	break;

	case 2: // forwards and receives packets. 1st layer of burst.
	      // Can receive from nodes 1, 4, 8, 15, and 33.
	      dbg("GroupProjectC", "Node 2 fwds to 1.");
	      //ret = call AMSend.send(1, call Queue.head(), sizeof(combined_msg_t));
	       ret = call AMSend.send(1, call Queue.head(), sizeof(group_project_msg_t));
	break;

	case 3: //forwards and receives packets. 2nd layer of burst.
	// Can receive from nodes 33, 32, 31, 6, 8, 15
	dbg("GroupProjectC", "Node 3 collects and sends to 1 \n");
	//TODO
	ret = call AMSend.send(1, call Queue.head(), sizeof(group_project_msg_t));
	
	break;

	case 4: //forwards and receives packets. 1st layer of burst.
	// Can receive from nodes 1, 2, 8, 15, and 33.
	dbg("GroupProjectC", "Node 4 sends to 1 \n");
	ret = call AMSend.send(1, call Queue.head(), sizeof(group_project_msg_t));
	
	break;

	case 6: //forwards and receives packets. 3rd layer of burst.
	// Can receive from nodes 3, 33, 28, 22, 16, 
	dbg("GroupProjectC", "Node 6 sends to 28 \n");
	ret = call AMSend.send(3, call Queue.head(), sizeof(group_project_msg_t));
	break;

	case 8: //forwards and receives packets. 1st layer of burst.
	// Can receive from nodes 1, 2, 4, 15, 33, 3 
	dbg("GroupProjectC", "Node 8 sends to 1\n");
	ret = call AMSend.send(1, call Queue.head(), sizeof(group_project_msg_t));
	break;

	case 15: //forwards and receives packets. 1st layer of burst.
	// Can receive from nodes 1, 2, 4, 8, 33, 3 
	dbg("GroupProjectC", "Node 15 sends to 1 \n");
	ret = call AMSend.send(1, call Queue.head(), sizeof(group_project_msg_t));
	
	break;

	case 16: //forwards and receives packets. 3rd layer of burst.
	// Can receive from nodes 6, 22, 28, 3
	dbg("GroupProjectC", "Node 16 sends to 28 \n");
	ret = call AMSend.send(3, call Queue.head(), sizeof(group_project_msg_t));
	
	break;

	case 22: //forwards and receives packets. 3rd layer of burst.
	// Can receive from nodes 6, 16, 28, 3
	dbg("GroupProjectC", "Node 22 sends to 28 \n");
	ret = call AMSend.send(3, call Queue.head(), sizeof(group_project_msg_t));
	
	break;

	case 28: //forwards and receives packets. 3rd layer of burst.
	// Can receive from nodes 6, 16, 22, 3, 33
	dbg("GroupProjectC", "Node 28 collects and forwards to 3 send now\n");
	ret = call AMSend.send(3, call Queue.head(), sizeof(group_project_msg_t));
	
	break;

	case 31: //forwards and receives packets. 2nd layer of burst.
	// Can receive from nodes 32, 33, 3, 28
	dbg("GroupProjectC", "Node 31 sends to 3 \n");
	ret = call AMSend.send(3, call Queue.head(), sizeof(group_project_msg_t));
	
	break;

	case 32: //forwards and receives packets. 2nd layer of burst.
	// Can receive from nodes 31, 3, 33, 15
	dbg("GroupProjectC", "Node 32 sends to 3 \n");
	ret = call AMSend.send(3, call Queue.head(), sizeof(group_project_msg_t));
	break;

	case 33: //forwards and receives packets. 2nd layer of burst.
	// Can receive from nodes 8, 15, 2, 3, 32, 31
	dbg("GroupProjectC", "Node 33 sends to 1 \n");
	ret = call AMSend.send(1, call Queue.head(), sizeof(group_project_msg_t));

	break;


	default:
	dbg("GroupProjectC", "OOOOOPS  we somehow missed a NODE. check it out!! \n");

      }//end switch
      
    if (ret != SUCCESS) 
    {
	dbg("GroupProjectC", "ERROR send failed to return an ACK. retrying soon.\n");
	 
    }
     // start send task again only after finished sending: in sendDone !!!
     
     
	  // TODO TRIAL REMOVE AFTER DONE TESTING
	  // 
	  //TEMPORARILY TURN OFF RADIO AFTER ONE SEND
	  //
	  //EITHER INCREASE PACKET PAYLOAD SIZE OR SEND AGAIN
// 	      if(TOS_NODE_ID != 1 && TOS_NODE_ID !=3  )
// 	      {
// 		  call AMControl.stop();
// 		  radioOn=FALSE;
// 		  startedRadioAlready=FALSE;
// 		  dbg("GroupProjectC", "Radio is OFF.\n");
// 	      }	
 	   //post sendTask();
 	  
 	  
    }//end if queue not empty
    else
    {//queue empty

//disabled    
//    dbg("GroupProjectC", "queue emtpty in send task (at end).\n");
      
	  // TODO TRIAL REMOVE AFTER DONE TESTING
	  // 
	  //TEMPORARILY TURN OFF RADIO AFTER ONE SEND
	  //
	  //EITHER INCREASE PACKET PAYLOAD SIZE OR SEND AGAIN
	      if(TOS_NODE_ID != 1 && TOS_NODE_ID !=3  )
	      {
		  call AMControl.stop();
		  radioOn=FALSE;
		  startedRadioAlready=FALSE;
		  dbg("GroupProjectC", "Radio is OFF.\n");
	      }	
      
    }
      
  
  

  

}

event void MilliTimer2.fired() {// aka radio turn on task

  if (!DataHasStartedArriving)
    return; // dont do anything if we dont have data


//  dbg("GroupProjectC", "MilliTimer2.fired(). making sure radio is on\n");
    

      if ( (radioOn == FALSE)  )  
      {
	if (startedRadioAlready == FALSE)
	{
	  dbg("GroupProjectC", "radio is off and is now being turned on.\n");
	  call AMControl.start();
	  startedRadioAlready = TRUE;
  //	startRadioTurnOnTimer();
	}
	else
	  //radio is booting, just wait
	  dbg("GroupProjectC", "radio is booting. !!! we need to change our radio timer!!!!\n");
	  // we should not get here anymore
      }
    
  
}
 
  
      
  event void MilliTimer.fired() {
 
    
    error_t ret;
    
  if (!DataHasStartedArriving)
    return; // dont do anything if we dont have data

    
//   dbg("GroupProjectC", "MilliTimer fired.\n");
    
    
        // sink node prints out data on serial port
//    dbg("GroupProjectC", "timer fired.\n");
  //  dbg("GroupProjectC", "This is the radios max payload length (%u).\n",call AMSend.maxPayloadLength());

//     if(TOS_NODE_ID == 28)
//     {
//       dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
//         call CC2420Config.setChannel(19);
// 	call CC2420Config.sync(); 
//       dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
//     } else
     if(TOS_NODE_ID == 3)
    {
      dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
        call CC2420Config.setChannel(26);
	call CC2420Config.sync(); 
      dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
    }

    post sendTask();
    
//     if (TOS_NODE_ID == SINK_ADDRESS && (!call Queue.empty()) ) 
//     {
//       if(locked)
//       {
//       dbg("GroupProjectC", "ERROR we are the sink and need to wait before send next msg.\n");
// 
// 	startCustomTimer(10);
// 	return;
//       }
//       dbg("GroupProjectC", "we are the sink and are now starting to send 1 element.\n");
// 
//       dbg("GroupProjectC", "p:%u q:%u\n", call Pool.size(), call Queue.size());
//     
// //       ret = call SerialSend.send(AM_BROADCAST_ADDR, call Queue.head(), sizeof(group_project_msg_t));
//        
//       dbg("GroupProjectC", "ret:%u  \n", ret);
//     }
    // other nodes forward data over radio
    
    
    

  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
 
 
//      dbg("GroupProjectC", "receive.receive msg cam in: source: %d seq_no: %d\n",((group_project_msg_t*)payload)->source,((group_project_msg_t*)payload)->seq_no);

     if (len != sizeof(group_project_msg_t)) 
    {return bufPtr;}
    else {
      return forward(bufPtr);
    }
//        combined_msg_t* received_msg = (combined_msg_t*) payload;
 /*
        if (len != sizeof(combined_msg_t))
        {
            dbg("GroupProjectC", "Message with wrong size received!\n");
            return bufPtr;
        }
        else 
	{
	 // return forward(bufPtr);
	}
	*/
      
    }    
      /*
      
      
    if (len != sizeof(group_project_msg_t)) 
      {
	return bufPtr;
        dbg("GroupProjectC", "received: %d.\n",*(int*)payload);
    }
    else 
    {
      // decide if we should forward our message
      
      //we are:     TOS_NODE_ID
      
      // from: 
       
      
      
      switch (TOS_NODE_ID)
      {
	case 1: //do shit and 100% duty cycling
	 // FlockLab nodes 1, 2, 3, 4, 6, 8, 15, 16, 22, 28, 31, 32, and 33
	dbg("GroupProjectC", "receive: node 1 enqueueing.\n");
	enqueue(bufPtr);  
	return bufPtr;
	break;

	case 2: // forwards and receives packets. 1st layer of burst.
	      // Can receive from nodes 1, 4, 8, 15, and 33.
	      dbg("GroupProjectC", "Try for lower duty cycles.");
	return bufPtr;
	break;

	case 3: //forwards and receives packets. 2nd layer of burst.
	// Can receive from nodes 33, 32, 31, 6, 8, 15
	dbg("GroupProjectC", "Node 3 Received a packet... forwadring.\n");
	  forward(bufPtr);
	break;

	case 4: //forwards and receives packets. 1st layer of burst.
	// Can receive from nodes 1, 2, 8, 15, and 33.
	dbg("GroupProjectC", "Node 4 Receives on 1st wave \n");
	return bufPtr;
	break;

	case 6: //forwards and receives packets. 3rd layer of burst.
	// Can receive from nodes 3, 33, 28, 22, 16, 
	dbg("GroupProjectC", "Node 6 Receives on 3rd wave of flood \n");
	return bufPtr;
	break;
	
	case 8: //forwards and receives packets. 1st layer of burst.
	// Can receive from nodes 1, 2, 4, 15, 33, 3 
	dbg("GroupProjectC", "Node 8 Receives on 1st wave of flood \n");
	return bufPtr;
	break;

	case 15: //forwards and receives packets. 1st layer of burst.
	// Can receive from nodes 1, 2, 4, 8, 33, 3 
	dbg("GroupProjectC", "Node 15 Receives on 1st wave of flood \n");
	return bufPtr;
	break;

	case 16: //forwards and receives packets. 3rd layer of burst.
	// Can receive from nodes 6, 22, 28, 3
	dbg("GroupProjectC", "Node 16 Receives on 3rd wave of flood \n");
	return bufPtr;
	break;

	case 22: //forwards and receives packets. 3rd layer of burst.
	// Can receive from nodes 6, 16, 28, 3
	dbg("GroupProjectC", "Node 22 Receives on 3rd wave of flood \n");
	return bufPtr;
	break;

	case 28: //forwards and receives packets. 3rd layer of burst.
	// Can receive from nodes 6, 16, 22, 3, 33
	dbg("GroupProjectC", "Node 28 Received packet enqueueing.\n");
	enqueue(bufPtr);  // or forward(bufPtr);
	return bufPtr;
	break;

	case 31: //forwards and receives packets. 2nd layer of burst.
	// Can receive from nodes 32, 33, 3, 28
	dbg("GroupProjectC", "Node 31 Receives on 2nd wave of flood \n");
	return bufPtr;
	break;

	case 32: //forwards and receives packets. 2nd layer of burst.
	// Can receive from nodes 31, 3, 33, 15
	dbg("GroupProjectC", "Node 32 Receives on 2nd wave of flood \n");
	return bufPtr;
	break;

	case 33: //forwards and receives packets. 2nd layer of burst.
	// Can receive from nodes 8, 15, 2, 3, 32, 31
	dbg("GroupProjectC", "Node 33 Receives on 2nd wave of flood \n");
	return bufPtr;
	break;


	default:
	return forward(bufPtr);  
      }
      
      
    }*/


  event void Notify.notify(group_project_msg_t datamsg) {
    
    message_t * m;
    group_project_msg_t* gpm;
    
    
    if (!DataHasStartedArriving && (TOS_NODE_ID==1 ||TOS_NODE_ID==3 ) )
    {// turn on listening radios for the first time
    	call AMControl.start();
    }
    
    DataHasStartedArriving = TRUE;
    
   // dbg("GroupProjectC", "Notify: we got more data: %d \n", datamsg);
    
    // call Leds.led0Toggle();
    
//    if(TOS_NODE_ID == 1 || TOS_NODE_ID ==3 || TOS_NODE_ID == 28)
      //startCustomTimer(3);  // dont fire immediately otherwise timing is corrupt
    
//     if (TOS_NODE_ID == 1)
//     {
//       
//       call SerialSend.send(AM_BROADCAST_ADDR, call Queue.head(), sizeof(group_project_msg_t));
//     }
  
      
      
      
    if (call Pool.size() < 10 )
    {
      dbg("GroupProjectC", "Notify: pool <10.\n");
      if (startedRadioAlready == FALSE)
      {
	dbg("GroupProjectC", "radio is off and is now being turned on.\n");
	call AMControl.start();
	startedRadioAlready = TRUE;
      }
      else if(radioOn == FALSE)
      {
	//radio is booting, just wait
	dbg("GroupProjectC", "radio is still booting.\n");
      }
      else
      {
	startImmediateTimer();
      }
    }
 
    
    
    m = call Pool.get();
    if (m == NULL) {
      dbg("GroupProjectC", "Notify: pool is empty => queue is full or pool returned null object.\n");
      return;
    }
    gpm = (group_project_msg_t*)call Packet.getPayload(m, sizeof(group_project_msg_t));
    *gpm = datamsg;
    // enqueue packet
    enqueue(m);
  }
  
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    senddone(bufPtr, error);
  }
  
  event void SerialSend.sendDone(message_t* bufPtr, error_t error) {
//     dbg("GroupProjectC", "send done error code(%u).\n", error); // kommt immer 0 heraus ist irgendwie defekt
    senddone(bufPtr, error);
  }
  
  error_t enqueue(message_t * m) {
    cache_entry_t c;
    // add message to queue
    if (call Queue.enqueue(m) == FAIL) {
      dbg("GroupProjectC", "ERROR drop(%u,%u).\n", c.source, c.seq_no);
      call Pool.put(m); // return buffer
      return FAIL;
    }
    
    // update cache
    message_to_cache_entry(m, &c);
    call Cache.insert(c);
    
    // if not sending, send first packet from queue
    //TODO is this right???
    if (!locked) {
   //   locked = TRUE;
      //startSlow3sTimer();
    }
// TODO temporarily disabled for speed on NODE 1 serial    
//    dbg("GroupProjectC", "enq(source:%u,seq_no:%u) p:%u q:%u\n", c.source, c.seq_no, call Pool.size(), call Queue.size());
    return SUCCESS;
  }
  
  message_t * forward(message_t * fm) {
    cache_entry_t c;

    // get spare message buffer
    message_t * m = call Pool.get();
    if (m == NULL) {
      dbg("GroupProjectC", "forward(): no more message buffers.\n");
      return fm; // no space available, return pointer to original message
    }
    
    // check if already forwarded
    message_to_cache_entry(fm, &c);
    if (call Cache.lookup(c)) {
      call Pool.put(m); // return buffer
      return fm;// already forwarded once
    }
    
    // enqueue for forwarding
    enqueue(fm);
    
    // return message buffer for next receive
    return m;
  }
  
  void message_to_cache_entry(message_t *m, cache_entry_t * c) {
    group_project_msg_t* gpm;
    gpm = (group_project_msg_t*)call Packet.getPayload(m, sizeof(group_project_msg_t));
    c->source = gpm->source;
    c->seq_no = gpm->seq_no;
  }
  
  void senddone(message_t* bufPtr, error_t error) {
//    dbg("GroupProjectC", "senddone  called.\n");
    
    if (error)
    dbg("GroupProjectC", "ERROR senddone(error_t)  error: %u\n", error);
	
	
    
    if (call Queue.head() == bufPtr) 
  { //if we are still at the head. 
      locked = FALSE;
      
      // remove from queue
      call Queue.dequeue(); // TODO ?? creates problems if item does not get transmitted with ack but still gets dequeued
	//  dbg("GroupProjectC", "senddone  dequeing element.\n");

      
      // return buffer
      call Pool.put(bufPtr);
      
      // send next waiting message
      //if (!call Queue.empty() && !locked) 
      if (!call Queue.empty()) 
      {
//	dbg("GroupProjectC", "queue not empty.\n");
//	dbg("GroupProjectC", "queue: p:%u q:%u\n", call Pool.size(), call Queue.size());
//        locked = TRUE;
	
	  // do work again
	  post sendTask();

// 	if(TOS_NODE_ID == 1 || TOS_NODE_ID ==3 || TOS_NODE_ID == 28)
// 	{ // send directly
// 	  startImmediateTimer();
// 	}
// 	else
// 	{
// 	  // only send every three seconds to conserve power
// 	  startImmediateTimer();
// 	}
        
      }
      else // TURN OFF RADIO 
      {      // only turn off if que is empty
      //filter for each node. only turn off on sending only nodes

      //disabled
      //      dbg("GroupProjectC", "queue  empty.\n");
      
      //change channels back
//       if(TOS_NODE_ID == 28)
//       {
// 	dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
// 	  call CC2420Config.setChannel(11);
// 	  call CC2420Config.sync(); 
// 	dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
//       }
      if(TOS_NODE_ID == 3)
      {
	dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
	  call CC2420Config.setChannel(20);
	  call CC2420Config.sync(); 
	dbg("GroupProjectC", "Radio channel is %u.\n", call CC2420Config.getChannel() )
      }
      
	if(TOS_NODE_ID != 1 && TOS_NODE_ID !=3  )
	{
	    call AMControl.stop();
	    radioOn=FALSE;
	    startedRadioAlready=FALSE;
	    dbg("GroupProjectC", "Radio is OFF.\n");
	 
	    
	    // synchronization timers 
// 	      if(TOS_NODE_ID == 6 || TOS_NODE_ID ==16 || TOS_NODE_ID == 22|| TOS_NODE_ID == 28)
// 		startCustomTimer(2000);
// 	      else if(TOS_NODE_ID == 31 || TOS_NODE_ID ==32 || TOS_NODE_ID == 3)
// 		startCustomTimer(3000);
// 	      else
// 		startCustomTimer(5000);
	   
	}
      }
	    
    }
  }
  
  
  
  void startRandomForwardTimer() 
  {
    uint16_t delay = call Random.rand16();
    delay=1 + delay % (FORWARD_DELAY_MS - 1);
    dbg("GroupProjectC", "retry in ms: %u.\n", delay )

//    call MilliTimer.startOneShot(delay);
  }
  
  void startCustomTimer(uint16_t delay) 
  {
//    call MilliTimer.startOneShot( delay);
  }
  
  void startSlow3sTimer() 
  {
    //uint16_t delay = call Random.rand16();
    uint16_t delay = 4000;
//    call MilliTimer.startOneShot( delay);
  }
  
    void startImmediateTimer() 
  {
    uint16_t delay = 0;
//    call MilliTimer.startOneShot(delay);
  }
  
      void startRadioTurnOnTimer() 
  {
    uint16_t delay = 4;
//    call MilliTimer.startOneShot(delay);
  }
  
    void startPeriodicAt(uint16_t t0_start, uint16_t dt_delay) 
  {
    uint16_t bitshifts=1;
    if (datarate==1)
      bitshifts = 5;  // 3 is like multiplying with 8
    if (datarate==10)
      bitshifts = 2;  // 3 is like multiplying with 8
    
    if (TOS_NODE_ID != 1 && TOS_NODE_ID !=3  )
    {
      call MilliTimer2.startPeriodicAt((t0_start << bitshifts),dt_delay << bitshifts); // starts radio before 
    } 
    call MilliTimer.startPeriodicAt((t0_start << bitshifts)+7,dt_delay << bitshifts);
  }
  
 
  
  
 

}
