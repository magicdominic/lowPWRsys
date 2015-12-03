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
 
module GroupProjectC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
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

  bool locked;
  bool radioOn;
  bool startedRadioAlready;
  uint8_t seq_no = 0;
  bool startedSlowTimer=FALSE;
  
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

  
  enum {
    FORWARD_DELAY_MS = 50, // max wait time between two forwarded packets
  };
  
  event void Boot.booted() 
  {
    if(TOS_NODE_ID == 1 || TOS_NODE_ID ==3 || TOS_NODE_ID == 28)
    {
      call AMControl.start();
    }
    
#ifndef COOJA
    call ClockCalibControl.start();
#endif
  }
  
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      radioOn=TRUE;
      call Leds.led1On();
      dbg("GroupProjectC", "Radio sucessfully booted, Radio is on, datarate is %u.\n", datarate);
    }
    else {
      call AMControl.start();
    }
  }
  
  event void AMControl.stopDone(error_t err) {
    // do nothing
    
  }
      
  event void MilliTimer.fired() {
    error_t ret;
    // sink node prints out data on serial port
    dbg("GroupProjectC", "timer fired.\n");
    dbg("GroupProjectC", "This is the radios max payload length (%u).\n",call AMSend.maxPayloadLength());
        
    if (radioOn == FALSE) 
    {
      if (startedRadioAlready == FALSE)
      {
	dbg("GroupProjectC", "radio is off and is now being turned on. testing my complier\n");
	call AMControl.start();
	startedRadioAlready = TRUE;
//	startRadioTurnOnTimer();
      }
      else
	//radio is booting, just wait
	dbg("GroupProjectC", "radio is booting. !!! we need to change our radio timer!!!!\n");
	// we should not get here anymore
    }
    
    if (TOS_NODE_ID == SINK_ADDRESS) 
    {
      dbg("GroupProjectC", "we are the sink and are now dequeing 1 element.\n");
      dbg("GroupProjectC", "enq( ) p:%u q:%u\n", call Pool.size(), call Queue.size());
    
       ret = call SerialSend.send(AM_BROADCAST_ADDR, call Queue.head(), sizeof(group_project_msg_t));
       
       dbg("GroupProjectC", "ret:%u  \n", ret);
    }
    // other nodes forward data over radio
    else 
    {
      dbg("GroupProjectC", "timer start switch.\n");
      switch (TOS_NODE_ID)
      {
	case 1: //do shit and 100% duty cycling
	 // FlockLab nodes 1, 2, 3, 4, 6, 8, 15, 16, 22, 28, 31, 32, and 33
	dbg("GroupProjectC", "not sending.\n");
	
	break;

	case 2: // forwards and receives packets. 1st layer of burst.
	      // Can receive from nodes 1, 4, 8, 15, and 33.
	      dbg("GroupProjectC", "Node 2 fwds to 1.");
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
	ret = call AMSend.send(28, call Queue.head(), sizeof(group_project_msg_t));
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
	ret = call AMSend.send(28, call Queue.head(), sizeof(group_project_msg_t));
	
	break;

	case 22: //forwards and receives packets. 3rd layer of burst.
	// Can receive from nodes 6, 16, 28, 3
	dbg("GroupProjectC", "Node 22 sends to 28 \n");
	ret = call AMSend.send(28, call Queue.head(), sizeof(group_project_msg_t));
	
	break;

	case 28: //forwards and receives packets. 3rd layer of burst.
	// Can receive from nodes 6, 16, 22, 3, 33
	dbg("GroupProjectC", "Node 28 collects and forwards to 3\n");
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
	dbg("GroupProjectC", "Node 33 sends to 3 \n");
	ret = call AMSend.send(3, call Queue.head(), sizeof(group_project_msg_t));

	break;


	default:
	dbg("GroupProjectC", "OOOOOPS  we somehow missed a NODE. check it out!! \n");

      }
      
      dbg("GroupProjectC", "done timer.\n");
 
      
      
    }
    
    if (ret != SUCCESS) 
    {
      if (TOS_NODE_ID != 1 && TOS_NODE_ID !=3 && TOS_NODE_ID != 28)
      {
	  startRandomForwardTimer(); // retry in a defined while
      }
      else
      {
	startRandomForwardTimer(); // retry in a defined while
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
          dbg("GroupProjectC", "message came in. \n");

    if (len != sizeof(group_project_msg_t)) 
      {return bufPtr;}
    else 
    {
      // decide if we should forward our message
      
      //we are:     TOS_NODE_ID
      
      // from: 
      
      dbg("GroupProjectC", "received: %d.\n",*(int*)payload);
      
      
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
	dbg("GroupProjectC", "Node 3 Received a packet... enqueueing.\n");
	enqueue(bufPtr);  
	return bufPtr;
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
	enqueue(bufPtr);  
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
      
      
    }
  }

  event void Notify.notify(group_project_msg_t datamsg) {
    
    message_t * m;
    group_project_msg_t* gpm;
    
   // dbg("GroupProjectC", "Notify: we got more data: %d \n", datamsg);
    
    // call Leds.led0Toggle();
    
    if(TOS_NODE_ID == 1 || TOS_NODE_ID ==3 || TOS_NODE_ID == 28)
      startImmediateTimer();
    
//     if (TOS_NODE_ID == 1)
//     {
//       
//       call SerialSend.send(AM_BROADCAST_ADDR, call Queue.head(), sizeof(group_project_msg_t));
//     }
    
    // start slow timer on first data item
    if (!startedSlowTimer)   
    {
	switch (TOS_NODE_ID)
	    {
	      case 1: //do shit and 100% duty cycling
	      // FlockLab nodes 1, 2, 3, 4, 6, 8, 15, 16, 22, 28, 31, 32, and 33
	      dbg("GroupProjectC", "receive: node 1 detected doing nothing.\n");
  		startCustomTimer(100);
		startedSlowTimer=TRUE;
	      break;

	      case 2: // forwards and receives packets. 1st layer of burst.
		    // Can receive from nodes 1, 4, 8, 15, and 33.
		    dbg("GroupProjectC", "Try for lower duty cycles.");
 		startCustomTimer(500);
		startedSlowTimer=TRUE;
	      break;

	      case 3: //forwards and receives packets. 2nd layer of burst.
	      // Can receive from nodes 33, 32, 31, 6, 8, 15
	      dbg("GroupProjectC", "Node 3 Receives on 2nd wave \n");
 		startCustomTimer(0);
		startedSlowTimer=TRUE; 
	      break;

	      case 4: //forwards and receives packets. 1st layer of burst.
	      // Can receive from nodes 1, 2, 8, 15, and 33.
	      dbg("GroupProjectC", "Node 4 Receives on 1st wave \n");
 		startCustomTimer(1000);
		startedSlowTimer=TRUE;
	      break;

	      case 6: //forwards and receives packets. 3rd layer of burst.
	      // Can receive from nodes 3, 33, 28, 22, 16, 
	      dbg("GroupProjectC", "Node 6 Receives on 3rd wave of flood \n");
		startCustomTimer(3000);
		startedSlowTimer=TRUE;
	      break;
	      
	      case 8: //forwards and receives packets. 1st layer of burst.
	      // Can receive from nodes 1, 2, 4, 15, 33, 3 
	      dbg("GroupProjectC", "Node 8 Receives on 1st wave of flood \n");
 		startCustomTimer(1500);
		startedSlowTimer=TRUE;
	      break;

	      case 15: //forwards and receives packets. 1st layer of burst.
	      // Can receive from nodes 1, 2, 4, 8, 33, 3 
	      dbg("GroupProjectC", "Node 15 Receives on 1st wave of flood \n");
 		startCustomTimer(1000);
		startedSlowTimer=TRUE;
	      break;

	      case 16: //forwards and receives packets. 3rd layer of burst.
	      // Can receive from nodes 6, 22, 28, 3
	      dbg("GroupProjectC", "Node 16 Receives on 3rd wave of flood \n");
		startCustomTimer(2000);
		startedSlowTimer=TRUE;
	      break;

	      case 22: //forwards and receives packets. 3rd layer of burst.
	      // Can receive from nodes 6, 16, 28, 3
	      dbg("GroupProjectC", "Node 22 Receives on 3rd wave of flood \n");
		startCustomTimer(1000);
		startedSlowTimer=TRUE;
	      break;

	      case 28: //forwards and receives packets. 3rd layer of burst.
	      // Can receive from nodes 6, 16, 22, 3, 33
	      dbg("GroupProjectC", "Node 28 Receives on 3rd wave of flood \n");
 		startCustomTimer(0);
		startedSlowTimer=TRUE;
	      break;

	      case 31: //forwards and receives packets. 2nd layer of burst.
	      // Can receive from nodes 32, 33, 3, 28
	      dbg("GroupProjectC", "Node 31 Receives on 2nd wave of flood \n");
 		startCustomTimer(1000);
		startedSlowTimer=TRUE;
	      break;

	      case 32: //forwards and receives packets. 2nd layer of burst.
	      // Can receive from nodes 31, 3, 33, 15
	      dbg("GroupProjectC", "Node 32 Receives on 2nd wave of flood \n");
 		startCustomTimer(2000);
		startedSlowTimer=TRUE;
	      break;

	      case 33: //forwards and receives packets. 2nd layer of burst.
	      // Can receive from nodes 8, 15, 2, 3, 32, 31
	      dbg("GroupProjectC", "Node 33 Receives on 2nd wave of flood \n");
 		startCustomTimer(3000);
		startedSlowTimer=TRUE;
	      break;


	      default:
	      
	    }
	    
   } // end if startedSlowTimer
      
      
      
      
      
    if (call Pool.size() < 7 )
    {
      dbg("GroupProjectC", "Notify: pool <7.\n");
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
    senddone(bufPtr, error);
  }
  
  error_t enqueue(message_t * m) {
    cache_entry_t c;
    // add message to queue
    if (call Queue.enqueue(m) == FAIL) {
      dbg("GroupProjectC", "drop(%u,%u).\n", c.source, c.seq_no);
      call Pool.put(m); // return buffer
      return FAIL;
    }
    
    // update cache
    message_to_cache_entry(m, &c);
    call Cache.insert(c);
    
    // if not sending, send first packet from queue
    //TODO is this right???
    if (!locked) {
      locked = TRUE;
      //startSlow3sTimer();
    }
    
    dbg("GroupProjectC", "enq(%u,%u) p:%u q:%u\n", c.source, c.seq_no, call Pool.size(), call Queue.size());
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
    dbg("GroupProjectC", "senddone  called.\n");
    
    if (call Queue.head() == bufPtr) {
      locked = FALSE;
      
      // remove from queue
      call Queue.dequeue();
      
      // return buffer
      call Pool.put(bufPtr);
      
      // send next waiting message
      //if (!call Queue.empty() && !locked) 
      if (!call Queue.empty()) 
      {
	dbg("GroupProjectC", "queue not empty.\n");
	dbg("GroupProjectC", "queue: p:%u q:%u\n", call Pool.size(), call Queue.size());
        locked = TRUE;
	startImmediateTimer();
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
      dbg("GroupProjectC", "queue  empty.\n");
	if(TOS_NODE_ID != 1 && TOS_NODE_ID !=3 && TOS_NODE_ID != 28)
	{
	    call AMControl.stop();
	    radioOn=FALSE;
	    startedRadioAlready=FALSE;
	    dbg("GroupProjectC", "Radio is OFF.\n");
	    startSlow3sTimer();
	}
      }
	    
    }
  }
  
  
  
  void startRandomForwardTimer() 
  {
    uint16_t delay = call Random.rand16();
    call MilliTimer.startOneShot(1 + delay % (FORWARD_DELAY_MS - 1));
  }
  
  void startCustomTimer(uint16_t delay) 
  {
    call MilliTimer.startOneShot( delay);
  }
  
  void startSlow3sTimer() 
  {
    //uint16_t delay = call Random.rand16();
    uint16_t delay = 4000;
    call MilliTimer.startOneShot( delay);
  }
  
    void startImmediateTimer() 
  {
    uint16_t delay = 0;
    call MilliTimer.startOneShot(delay);
  }
  
      void startRadioTurnOnTimer() 
  {
    uint16_t delay = 4;
    call MilliTimer.startOneShot(delay);
  }
  
  
 

}
