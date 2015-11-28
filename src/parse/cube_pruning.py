# -*- coding: utf-8 -*-
import copy, time
from heapq import heappush, heappop

class EisnerHeap():
    def __init__(self, k):
        self.bestK = k
        self.cube = [None for i in xrange(k)]
        self.buf = []
        self.heap = []
        self.state = ()
    
    def setState(self, s, t, direction, shape):
        self.state = (s, t, direction, shape)
    
    def __getitem__(self, k):
        return self.buf[k]
    
    def findKBest(self, node, nodeGen):
        score = node[0]
        mid_index = node[1]
        left_heap = node[2][0]
        left_index = node[2][1]
        right_heap = node[3][0]
        right_index = node[3][1]

        if self.cube[node[1]] == None:
            self.cube[node[1]] = [[None for i in xrange(self.bestK)] for j in xrange(self.bestK)]
        self.cube[node[1]][node[2][1]][node[3][1]] = node[0]
        
        for i in [(-1,0), (1,0), (0,-1), (0,1)]:
            left = node[2][1] + i[0]
            right = node[3][1] + i[1]
            if left >= 0 and left < self.bestK and right >= 0 and right < self.bestK:
                if self.cube[node[1]][left][right] is not None:
                    continue
                score = left_heap[left][0] + right_heap[right][0] + \
                        nodeGen(self, left_heap[left], right_heap[right])
                heappush(self.heap, (score, mid_index, (left_heap, left), (right_heap, right)))

    def explore(self, stateGen):
        while self.heap is not [] and len(self.buf) < bestK:
            newNode = heappop(self.heap)
            pushheap(self.buf, newNode)
            self.findKBest(newNode, stateGen)

class CubePruningParser():
    """
    An Eisner parsing algorithm implementation
    """
    
    def __init__(self):
        return
        
    def init_eisner_matrix(self,n):
        """
        Initialize a dynamic programming table, i.e. e[0..n][0..n][0..1][0..1]

        :param n: The length of the sentence including the artificial ROOT
        :type n: integer

        :return: An initialized table with all chart entries being (0,[])
        :rtype: Multi-dimensional list
        """
        # CAUTION: Must use deepcopy() here, since Python uses the object
        # reference model, which will cause trouble if we use shared object
        # in the chart
        # The last dimenison of the table. It uses a tuple to store score
        # and edges of current stage
        e1 = [copy.deepcopy(EisnerHeap(3)) for i in range(2)]
        # The dimension that specifies the direction of the edge
        e2 = [copy.deepcopy(e1) for i in range(2)]
        # The end of the span
        e3 = [copy.deepcopy(e2) for i in range(n)]
        # The start of the span
        e4 = [copy.deepcopy(e3) for i in range(n)]
        for i in xrange(n):
            for j in xrange(n):
                for k in xrange(2):
                    for l in xrange(2):
                        e4[i][j][k][l].setState(i, j, k, l)
        return e4

    def get_edge_list(self, e, n):
        edge_list = []
        heap = []
        headNode = (e[0][n-1][1][0][0], e[0][n-1][1][0].state)
        heap.append(headNode)
        while len(heap) is not 0:
            push = false
            node = heap.pop(0)
            state = node[1]
            left_heap = node[0][2][0]
            left_index = node[0][2][1]
            right_heap = node[0][3][0]
            right_index = node[0][3][1]

            left_node = (left_heap[left_index], left_heap.state)
            right_node = (right_heap[right_index], right_heap.state)
            
            if state[3] == 1 and state[2] == 1:
                edge_list.append((state[0], state[1]))
            if state[3] == 0 and state[2] == 1:
                edge_list.append(state[1], state[0])
            
            if left_node[1][0] is not left_node[1][1]:
                heap.append(left_node)
            if right_node[1][0] is not right_node[1][1]:
                heap.append(right_node)
        return edge_list 
            

    def trapezoidGenLeft(self, heap, left, right):
        score = arc_weight(sentence.get_local_vector(heap.state(1), heap.state(0), [right[1]], 1))\
              + arc_weight(sentence.get_local_vector(heap.state(1), heap.state(0), [left[1]], 2))
        return -score

    def trapezoidGenRight(self, heap, left, right):
        score = arc_weight(sentence.get_local_vector(heap.state(0), heap.state(1), [left[1]], 1))\
              + arc_weight(sentence.get_local_vector(heap.state(0), heap.state(1), [right[1]], 2))
        return -score

    def triangleGenLeft(self, heap, left, right):
        score = arc_weight(sentence.get_local_vector(heap.state(1), heap.state(0), [left[1]], 2))
        return -score

    def triangleGenRight(self, heap, left, right):
        score = arc_weight(sentence.get_local_vector(heap.state(0), heap.state(1), [right[1]], 2))
        return -score

    def parse(self,sentence, arc_weight):
        """
        Implementation of Eisner Algorithm using dynamic programming table
        
        :param n: The number of input words that constitute a sentence.
        :type n: int
        :param arc_weight: A scoring function that gives scores to edges
        :type arc_weight: function(head_node,child_node)

        :return: The maximum score of the dependency structure as well as all edges
        :rtype: tuple(integer,list(tuple(integer,integer)))
        """
        #tt = 0;
        n = len(sentence.word_list)
        e = self.init_eisner_matrix(n)
        for m in range(1, n):
            for s in range(0, n):
                t = s + m
                if t >= n:
                    break
                #t1 = time.clock()
 
                for q in range(s, t):
                    score = self.trapezoidGenLeft(e[s][t][0][1], e[s][q][1][0][0], e[q+1][t][0][0])
                    heappush(e[s][t][0][1].heap, (score, q, (e[s][q][1][0],0), (e[q+1][t][0][0],0)))

                e[s][t][0][1].explore(self.trapezoidGenLeft)
                
                #t1 = time.clock()

                for q in range(s, t):
                    score = self.trapezoidGenRight(e[s][t][1][1], e[s][q][1][0][0], e[q+1][t][0][0][0])
                    heappush(e[s][t][1][1].heap, (score, q, (e[s][q][1][0], 0), (e[q+1][t][0][0],0)))
                
                e[s][t][1][1].explore(self.trapzoidGenRight)

                
                for q in range(s, t):
                    score = self.triangleGenLeft(e[s][t][0][0], e[s][q][0][0][0], e[q][t][0][1][0])
                    heappush(e[s][t][0][0].heap, (score, q, (e[s][q][0][0], 0), (e[q][0][1],0)))

                e[s][t][0][0].explore(self.triangleGenLeft)

                
                for q in range(s+1, t+1):
                    score = self.triangleGenRight(e[s][t][1][0], e[s][q][1][1][0], e[q][t][1][0][0])
                    heappush(e[s][t][1][0].heap, (score, q, (e[s][q][1][1],0), (e[q][t][1][0],0)))

                e[s][t][1][0].explore(self.triangleGenRight)

        #print "edge query time", tt    
        return edge_list
    
