opcodes = {
    'STORE': '1111', 
    'LOAD': '1000',
    'LOADI': '0110',
    'AND': '0000',
    'OR': '0001',
    'XOR': '0010',
    'SLL': '0011',  
    'SRL': '0100',  
    'SUB': '0101',
    'ADD': '0111',
    'CMP': '1001',  
    'MOV1': '1010',  
    'JEQ': '1011',   
    'JGE': '1100',   
    'JLE': '1101',   
    'MOV2': '1110'   
}

register_map = {
    "R0": "000",
    "R1": "001",
    "R2": "010",
    "R3": "011",
    "R4": "100",
    "R5": "101",
    "R6": "110",
    "R7": "111"
}

def decimal_to_binary(value, bits):
    return format(value, f"0{bits}b")

def collect_labels(assembly_code):
    label_address_map = {}
    address_counter = 0

    for instruction in assembly_code:
        instruction = instruction.strip()
        if instruction.endswith(":"):
            label = instruction[:-1]
            label_address_map[label] = address_counter
        else:
            address_counter += 1

    return label_address_map

def assemble_instruction(instruction, label_address_map):
    parts = instruction.split()
    mnemonic = parts[0]
    operands = parts[1:]
    print(mnemonic)
    if mnemonic in opcodes:
        opcode = opcodes[mnemonic]
        machine_code = opcode

        if mnemonic == 'loadi':
            reg = register_map[operands[0]]
            imm_value = int(operands[1])
            machine_code += reg + decimal_to_binary(imm_value, 3)
        else:
            reg_code = ''
            for operand in operands:
                if operand in register_map:
                    reg_code += register_map[operand]
                elif operand.isdigit():
                    reg_code += decimal_to_binary(int(operand), 3)
                elif operand in label_address_map:
                    address = label_address_map[operand]
                    reg_code += decimal_to_binary(address, 3)
            machine_code += reg_code
    else:
        return "Error: Unknown instruction"

    return machine_code

def assemble_program(assembly_code, label_address_map):
    machine_code = []
    for instruction in assembly_code:
        instruction = instruction.strip()
        if not instruction.endswith(":"):
            machine_code.append(assemble_instruction(instruction, label_address_map))
    return machine_code

assembly_code = [
    # Include real assembly code here
    "LOADI R2 2",
    "LOADI R3 0",
    "OUTER_LOOP:",
    "CMP R0 R2",
    "JEQ END_OUTER_LOOP",
    "MOV R1 R0",
    "ADD R1 R1",
    "INNER_LOOP:",
    "CMP R1 R2",
    "JEQ END_INNER_LOOP",
    "MOV R5 R0",
    "SLL R5 1",
    "LOAD R6 R5",
    "ADD R5 R5",
    "LOAD R6 [R5]",
    "MOV R5 R1",
    "SLL R5 1",
    "LOAD R7 R5",
    "ADD R5 R5",
    "LOAD R7 [R5]",
    "XOR R6 R7",
    "MOV R4 0",
    "COUNT_HAMMING:",
    "AND R8 R6 1",
    "ADD R4 R4 R8",
    "SRL R6 1",
    "CMP R6 0",
    "JNE COUNT_HAMMING",
    "CMP R4 R2",
    "JGE SKIP_MIN_UPDATE",
    "MOV R2 R4",
    "SKIP_MIN_UPDATE:",
    "CMP R4 R3",
    "JLE SKIP_MAX_UPDATE",
    "MOV R3 R4",
    "SKIP_MAX_UPDATE:",
    "ADD R1 R1",
    "JMP INNER_LOOP",
    "END_INNER_LOOP:",
    "ADD R0 R0",
    "JMP OUTER_LOOP",
    "END_OUTER_LOOP:",
    "STORE [64] R2",
    "STORE [65] R3"
]

label_address_map = collect_labels(assembly_code)
machine_code = assemble_program(assembly_code, label_address_map)

# Save to file
with open("progmach.txt", "w") as f:
    for instruction in machine_code:
        f.write(instruction + "\n")
